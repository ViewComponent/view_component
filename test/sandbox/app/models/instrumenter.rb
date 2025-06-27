class Instrumenter
  cattr_accessor :count, instance_reader: false, instance_writer: false, instance_accessor: false, default: 0

  def self.tick
    Instrumenter.count = Instrumenter.count + 1
    yield
  end
end
