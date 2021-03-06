require 'jbuilder'

module Gon
  module Jbuilder
    class << self

      def parse_source(source, controller)
        output = ::JbuilderTemplate.encode(controller) do |json|
          eval source
        end
        JSON.parse(output)
      end

      def parse_jbuilder(jbuilder_path, controller)
        controller.instance_variables.each do |name|
          self.instance_variable_set(name, controller.instance_variable_get(name))
        end
        lines = find_partials(File.readlines(jbuilder_path))
        source = lines.join('')

        output = parse_source(source, controller)
      end

      def parse_partial(partial_line)
        path = partial_line.match(/['"]([^'"]*)['"]/)[1]
        options_hash = partial_line.match(/,(.*)/)[1]
        if options_hash.present?
          options = eval '{' + options_hash + '}'
          options.each do |name, val|
            self.instance_variable_set('@' + name.to_s, val)
            eval "def #{name}; self.instance_variable_get('@' + '#{name.to_s}'); end"
          end
        end
        find_partials(File.readlines(path))
      end

      def find_partials(lines = [])
        lines.map do |line|
          if line =~ /partial!/
            parse_partial(line)
          else
            line
          end
        end.flatten
      end

    end
  end
end
