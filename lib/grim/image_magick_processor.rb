module Grim
  class ImageMagickProcessor

    # ghostscript prints out a warning, this regex matches it
    WarningRegex = /\*\*\*\*.*\n/

    def initialize(options={})
      @imagemagick_path = options[:imagemagick_path] || 'convert'
      @ghostscript_path = options[:ghostscript_path]
      @original_path        = ENV['PATH']
    end

    def count(path)
      command = ["-dNODISPLAY", "-q",
        "-sFile=#{Shellwords.shellescape(path)}",
        File.expand_path('../../../lib/pdf_info.ps', __FILE__)]
      @ghostscript_path ? command.unshift(@ghostscript_path) : command.unshift('gs')
      result = `#{command.join(' ')}`
      result.gsub(WarningRegex, '').to_i
    end

    def save(pdf, index, path, options)
      width   = options[:width] ? options[:width] : Grim::WIDTH
      density = options[:density] ? options[:density] : Grim::DENSITY
      quality = options[:quality] ? options[:quality] : Grim::QUALITY
      colorspace = options.fetch(:colorspace, Grim::COLORSPACE)
      command = [@imagemagick_path, "-resize", width.to_s, "-antialias", "-render",
        "-quality", quality.to_s, "-colorspace", colorspace,
        "-interlace", "none", "-density", density.to_s]
      options.each do |opt|
        command += ["-" + opt[0].to_s, opt[1]] if opt[0] != :width and opt[0] != :density and opt[0] != :quality
      end
      command += ["#{Shellwords.shellescape(pdf.path)}[#{index}]", path]
      command.unshift("PATH=#{File.dirname(@ghostscript_path)}:#{ENV['PATH']}") if @ghostscript_path

      result = `#{command.join(' ')}`

      $? == 0 || raise(UnprocessablePage, result)
    end
  end
end
