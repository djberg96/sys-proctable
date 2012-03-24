require 'sys/proctable'

# The Sys module serves as a namespace only
module Sys

  # The Top class serves as a toplevel name for the 'top' method.
  class Top

    # The version of the sys-top library
    VERSION = '1.0.3'

    # Returns an array of Struct::ProcTableStruct elements containing up
    # to +num+ elements, sorted by +field+. The default number of elements
    # is 10, while the default field is 'pctcpu'.
    #
    # Exception: the default sort field is 'pid' on Linux and Windows.
    #
    def self.top(num=10, field='pctcpu')
      field = field.to_s if field.is_a?(Symbol)

      # Sort by pid on Windows by default
      if File::ALT_SEPARATOR && field == 'pctcpu'
        field = 'pid'
      end

      Sys::ProcTable.ps.sort_by{ |obj| obj.send(field) || '' }[0..num-1]
    end
  end
end
