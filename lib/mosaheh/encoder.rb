# encoding: UTF-8

class Mosaheh::Encoder
  
  # Initialize the encoder
  def initialize
    # UTF-8 bytes-sequences always begin with one of (0xD8 - 0xDB) for Arabic
    @utf_8_beginning_chars = [*216..219].map(&:chr).join.force_encoding('cp1252')

    # Misencoded sequences can be correctly re-encoded to utf-8, EXCEPT for one
    # charecter with gets replaced with a space (ASCII for it: 32)!
    @problem_char = 32.chr.force_encoding('cp1252')

    # The correct replacement for the problem charecter 
    @correct_char = 160.chr.force_encoding('cp1252')
  end
  
  # Repairs Arabic (U+0600 - U+06FF) data
  # which has been misencoded from cp1252 to UTF-8
  # although the original data was UTF-8 encoded
  #
  # @param [String] Misencoded string
  # @return [String] Correctly encoded utf-8 string
  def repair(str)
    
    # Data buffers
    source = str.clone
    fixed  = ""
    
    # Each string needs a new converter instance
    ec  = Encoding::Converter.new('utf-8', 'cp1252')
    
    until source.empty?

      # Don't process correctly UTF-8 
      # encoded Arabic data
      if is_arabic?(source[0])
        fixed += source[0]
        source[0] = ''
        next
      end

      state = ec.primitive_convert(source, fixed, nil, nil, Encoding::Converter::AFTER_OUTPUT)

      if state == :undefined_conversion 
        c = ec.last_error.error_char.unpack('C*')[1].chr
        fixed += c.force_encoding('cp1252')
      end

      if state == :after_output && fixed =~ %r{[#{@utf_8_beginning_chars}]#{@problem_char}$}
        fixed.gsub!(/#{@problem_char}$/, @correct_char)
      end
    end

    fixed.force_encoding('utf-8')
  end

private
  
  def is_arabic?(str)
    str =~ %r{([\u0600-\u06FF])+}u
  end

end
