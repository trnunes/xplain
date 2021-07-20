class Xplain::SetSequence
  
  def self.next
    seq = 1
    if !File.exist? Xplain.base_dir + "setsequence.txt"
      self.reset
      return seq
    end
    
    f = File.open Xplain.base_dir + "setsequence.txt", 'r'
    seq = f.readlines.first.to_i
    seq += 1
    f.close
    
    f = File.open Xplain.base_dir + "setsequence.txt", 'w'
    f.write_nonblock seq.to_s
    f.flush
    f.close
    seq
  end
  
  def self.reset
    f = File.open Xplain.base_dir + "setsequence.txt", 'w'
    f.write_nonblock 0.to_s
    f.flush
    f.close
  end
  
  
end