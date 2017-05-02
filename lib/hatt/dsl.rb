require_relative 'configuration'
require_relative 'log'

module Hatt
  module DSL
    include Hatt::Configuration
    include Hatt::Log

    def load_hatts_using_configuration
      hatt_globs = hatt_configuration['hatt_globs']
      if hatt_configuration['hatt_config_file']
        debug "Using HATT configuration file: #{hatt_configuration['hatt_config_file']}"
        glob_home_dir = File.dirname hatt_configuration['hatt_config_file']
        hatt_globs.map! { |g| File.join glob_home_dir, g }
      else
        debug 'Not using a hatt configuration file (none defined).'
      end
      if hatt_globs.is_a? Array
        hatt_globs.each do |gg|
          hatt_load_hatt_glob gg
        end
      end
      nil
    end

    def hatt_load_hatt_glob(glob)
      globbed_files = Dir[glob]
      Log.debug "Found '#{globbed_files.length}' hatt files using hatt glob '#{glob}'"
      Dir[glob].each do |filename|
        hatt_load_hatt_file filename
      end
    end

    def hatt_load_hatt_file(filename)
      Log.debug "Loading hatt file '#{filename}'"

      unless File.exist? filename
        raise HattNoSuchHattFile, "No such hatt file '#{filename}'"
      end

      # by evaling in a anonymous module, we protect this class's namespace
      anon_mod = Module.new
      with_local_load_path File.dirname(filename) do
        anon_mod.class_eval(IO.read(filename), filename, 1)
      end
      extend anon_mod
    end

    private

    def with_local_load_path(load_path, &block)
      $LOAD_PATH << load_path
      rtn = yield block
      # delete only the first occurrence, in case something else if changing load path too
      idx = $LOAD_PATH.index(load_path)
      $LOAD_PATH.delete_at(idx) if idx
      rtn
    end
  end

  class HattNoSuchHattFile < StandardError; end
end
