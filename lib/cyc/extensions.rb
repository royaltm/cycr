class String
  def to_cyc(raw=false)
    "\"#{self}\""
  end
end

class Symbol
  def to_cyc(raw=false)
    "#\$#{self}"
  end
end

class Array
  def to_cyc(raw=false)
    contents = "("+map{|e| e.to_cyc(true)}.join(" ")+")"
    if raw
      contents
    else
      "(el-find-if-nart '#{contents})"
    end
  end
end

class Fixnum
  def to_cyc(raw=false)
    to_s
  end
end

class Proc
  def to_cyc(raw=false)
    self.call.to_s
  end
end

module Cyc
  class LiteralString < String
    def to_cyc(raw=false)
      self
    end
  end
end
