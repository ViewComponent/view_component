# frozen_string_literal: true

require "test_helper"
require "fileutils"

# Regression test for GHSA-hg3h-g7xc-f7vp:
# The system test entrypoint validates a file path using String#start_with?,
# which is not a safe containment check. A sibling directory that shares the
# same string prefix as the allowed temp directory (e.g. tmp/view_components_evil
# vs tmp/view_components) passes the check even though it is outside the
# intended directory. The route then renders the resolved file.
class SystemTestEntrypointPathTraversalPocTest < ActionDispatch::IntegrationTest
  def test_system_test_entrypoint_rejects_sibling_directory_with_same_prefix
    base_dir = File.realpath(ViewComponentsSystemTestController.temp_dir)
    parent_dir = File.dirname(base_dir)
    sibling_name = "#{File.basename(base_dir)}_evil"
    sibling_dir = File.join(parent_dir, sibling_name)
    outside_file = File.join(sibling_dir, "secret.html.erb")

    FileUtils.mkdir_p(sibling_dir)
    File.write(outside_file, "<div>VC_SYSTEM_TEST_TRAVERSAL_POC</div>")

    # The sibling path shares the string prefix of base_dir, so the unfixed
    # start_with? check incorrectly allows it through and returns 200.
    get "/_system_test_entrypoint", params: {file: "../#{sibling_name}/secret.html.erb"}

    assert_response :not_found
  ensure
    FileUtils.rm_f(outside_file) if defined?(outside_file) && outside_file
    Dir.rmdir(sibling_dir) if defined?(sibling_dir) && sibling_dir && Dir.exist?(sibling_dir)
  end
end
