class Protobuf::Schema
  class Parser
    def initialize(@buf : String)
    end

    # now supports first occurred schema only
    def parse : Schema
      group_seq  = 0
      klass_name = nil
      lines      = Array(Field | Text).new
      version    = 3

      @buf.split(/\n/).each do |line|
        case line
        when /^\s*syntax\s*=\s*"proto(\d+)"\s*;/
          version = $1.to_i
          lines << Text.new(line)
        when /^\s*((optional|repeated|required)\s+)?(.*?)\s+(.*?)\s*=\s*(\d+)\s*;(.*?)$/
          rule,type,name,num,rest = $2?,$3,$4,$5,$6
          num = num.to_i? || raise ArgumentError.new("protobuf schema error: #{name} lacks tag_id")
          memo = rest.sub(%r{\A\s*//}, "").strip
          packed = false        # TODO
          lines << Field.new(version, rule, type, name, num, packed, memo)
        else
          if line =~ /^\s*message\s+([^\s]+)/
            group_seq += 1
            break if group_seq > 1
            klass_name = $1.strip
          end
          lines << Text.new(line)
        end
      end

      klass_name || raise ArgumentError.new("class name not found")
      return Schema.new(version, klass_name, lines)
    end
  end
end
