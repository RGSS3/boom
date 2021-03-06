# coding: utf-8

# Platform is a centralized point to shell out platform specific functionality
# like clipboard access or commands to open URLs.
#
#
# Clipboard is a centralized point to shell out to each individual platform's
# clipboard, pasteboard, or whatever they decide to call it.
#
module Boom
  class Platform
    class << self
      # Public: tests if currently running on cygwin.
      #
      # Returns true if running on Cygwin, else false
      def cygwin?
        !!(RbConfig::CONFIG['host_os'] =~ /cygwin/)
      end

      # Public: tests if currently running on darwin.
      #
      # Returns true if running on darwin (MacOS X), else false
      def darwin?
        !!(RbConfig::CONFIG['host_os'] =~ /darwin/)
      end

      # Public: tests if currently running on windows.
      #
      # Apparently Windows RUBY_PLATFORM can be 'win32' or 'mingw32'
      #
      # Returns true if running on windows (win32/mingw32), else false
      def windows?
        !!(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/)
      end

      # Public: returns the command used to open a file or URL
      # for the current platform.
      #
      # Currently only supports MacOS X and Linux with `xdg-open`.
      #
      # Returns a String with the bin
      def open_command
        if darwin?
          'open'
        elsif windows?
          'start'
        elsif cygwin?
          'cygstart'
        else
          'xdg-open'
        end
      end

      # Public: opens a given Item's value in the browser. This
      # method is designed to handle multiple platforms.
      #
      # Returns a String of the Item value.
      def open(item)
        unless windows?
          system("#{open_command} '#{item.url.gsub("\'","'\\\\''")}'")
        else
          system("#{open_command} #{item.url.gsub("\'","'\\\\''")}")
        end

        item.value
      end

      # Public: returns the command used to copy a given Item's value to the
      # clipboard for the current platform.
      #
      # Returns a String with the bin
      def copy_command
        if darwin?
          'pbcopy'
        elsif windows? || cygwin?
          'clip'
        else
          'xclip -selection clipboard'
        end
      end

      # Public: copies a given Item's value to the clipboard. This method is
      # designed to handle multiple platforms.
      #
      # Returns the String value of the Item.
      def copy(item)
        if item.name.end_with?('$')
          Boom::SeiranCopy.qqimage(item.value[1])
          "Image #{item.value[0]}"
        else
          begin
            IO.popen(copy_command,"w") {|cc|  cc.write(item.value)}
            item.value
          rescue Errno::ENOENT
            puts item.value
            puts "Please install #{copy_command[0..5]} to copy this item to your clipboard"
            exit
          end
        end
      end

      # Public: opens the JSON file in an editor for you to edit. Uses the
      # $EDITOR environment variable, or %EDITOR% on Windows for editing.
      # This method is designed to handle multiple platforms.
      # If $EDITOR is nil, try to open using the open_command.
      #
      # Returns a String with a helpful message.
      def edit(json_file)
        unless ENV['EDITOR'].nil?
          unless windows?
            system("`echo $EDITOR` #{json_file} &")
          else
            system("start %EDITOR% #{json_file}")
          end
        else
          system("#{open_command} #{json_file}")
        end

        "Make your edits, and do be sure to save."
      end
    end
  end
end
