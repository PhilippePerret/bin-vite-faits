# encoding: UTF-8
class Array
  def to_sym
    self.collect do |item|
      case item
      when Hash, Array
        item.to_sym
      else
        item
      end
    end
  end
end

class Hash
  def to_sym
    h = {}
    self.each do |k, v|
      case v
      when Hash, Array
        v = v.to_sym
      end
      h.merge!(k => v)
    end
    return h
  end
end
