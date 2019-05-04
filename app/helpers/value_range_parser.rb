require 'number_date_parser'

class ValueRangeParser < ParserAbstract

private
  def build_tokens
    @tokens= input.split TOKENS_SEPARATOR
  end

end


class NumberParser < NumberDateParser
  def convert
    @value= @input.to_f
  end

  def valueConstructor(a)
    a.first + a.last    
  end
end


class DateParser < NumberDateParser
  MARK_PREFIX='%'

  class Formatter
    attr_accessor :token,:value
    def initialize(hash)
      hash.each { |k,v| instance_variable_set("@#{k}",v) unless v.nil? }
    end

    def pattern; '%02d'; end
    def printv(value,output)  
      output.gsub!(mark,format(pattern,value))
    end
    def mark; MARK_PREFIX+self.class.mark_char; end
    def min_value; 0; end; 
    def zero_default; min_value; end;
    def sysdate_default; Time.now.strftime(mark).to_i; end;
   
    def process(state)
      if !token.blank?
        res= token.to_i
      else
        res=self.send state[:zero_handler]
      end 
      self.value=res
    end
 
  end
  
  @@formatters = [ :Year,:month,:day,:Hour,:Minute,:Second].inject( []) do  | s, sym |
     s << ( self.class_eval <<-CLASS_DEF
      class #{sym.to_s.capitalize} < Formatter
        def self.mark_char; '#{sym.to_s.first}'; end       
        def self.min_value; 1; end
        self
      end
     CLASS_DEF
    )
  end
#  Formatters = [Formatter]*6
  def self.formatters; @@formatters; end
  def self.all_formatter_marks; formatters.map{|e| e.mark_char}.join; end

  def value_constructor a
    DateTime.new *a
  end


  def to_SQLite
    value.strftime"datetime('%Y-%m-%d-%H-%M-%S')"
  end
end
