a = $VERBOSE
$VERBOSE = nil
require 'win32api'
$VERBOSE = a


module Boom
    module SeiranCopy
        def self.qqimage(str)
            text =  '<QQRichEditFormat><Info version="1001"></Info><EditElement type="1" filepath="' + 
                    str + 
                    '" shortcut=""></EditElement></QQRichEditFormat>\0'
            o = Module.new do
                def self.api(func)
                    lambda{|*args|
                        ["Kernel32", "User32"].each{|dll|
                            begin
                                return Win32API.new(dll, func, args.map{|x| Integer === x ? "L" : "p"}, "L").call(*args)
                            rescue LoadError
                            end
                        }
                        raise "Can't find #{func}"
                    }
                end

                def self.method_missing(sym, *args)
                    api(sym.to_s).call(*args)
                end
            end


            o = O.new
            flag = o.RegisterClipboardFormat("QQ_RichEdit_Format")
            str = o.GlobalAlloc(66, TEXT.length)
            if str != 0
                mem = o.GlobalLock(str)
                if mem != 0
                    o.RtlMoveMemory(mem, TEXT, TEXT.length)
                    o.GlobalUnlock(str)
                else 
                    raise "Lock Failed"
                end
                o.OpenClipboard 0
                o.EmptyClipboard
                o.SetClipboardData flag, str
                o.CloseClipboard
            else
                raise "Alloc Failed"
            end
        end
    end
end