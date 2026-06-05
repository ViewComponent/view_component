# frozen_string_literal: true

require "rubygems"

# Force `cgi/cookie` to load so the `@@accept_charset` class variable is defined
# on `CGI` before `globalid` calls into `CGI::Escape.unescape` (a C extension
# that reads the cvar via `rb_cvar_get`). On Ruby 3.5 the cvar isn't defined
# soon enough through the default require chain and `globalid`'s Railtie
# crashes at boot.
require "cgi"

$:.unshift File.expand_path("../../../../../../lib", __FILE__)
