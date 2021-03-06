module FFI; module Inliner

Compiler.define :gcc do
  def exists?
    `gcc -v 2>&1'`; $?.success?
  end

  def compile (code, libraries = [])
    @code      = code
    @libraries = libraries

    return output if File.exists?(output)

    unless system(if RbConfig::CONFIG['target_os'] =~ /mswin|mingw/
      "sh -c '#{ldshared} #{ENV['CFLAGS']} -o #{output.shellescape} #{input.shellescape} #{libs}' 2>#{log.shellescape}"
    else
      "#{ldshared} #{ENV['CFLAGS']} -o #{output.shellescape} #{input.shellescape} #{libs} 2>#{log.shellescape}"
    end)
      raise CompilationError.new(log)
    end

    output
  end

  private
  def digest
    Digest::SHA1.hexdigest(@code + @libraries.to_s + @options.to_s)
  end

  def input
    File.join(Inliner.directory, "#{digest}.c").tap {|path|
      File.open(path, 'w') { |f| f.write(@code) } unless File.exists?(path)
    }
  end

  def output
    File.join(Inliner.directory, "#{digest}.#{Compiler::Extension}")
  end

  def log
    File.join(Inliner.directory, "#{digest}.log")
  end

  def ldshared
    if RbConfig::CONFIG['target_os'] =~ /darwin/
      "gcc -dynamic -bundle -fPIC #{options} #{ENV['LDFLAGS']}"
    else
      "gcc -shared -fPIC #{options} #{ENV['LDFLAGS']}"
    end
  end

  def libs
    @libraries.map { |lib| "-l#{lib}".shellescape }.join(' ')
  end
end

end; end
