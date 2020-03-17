Facter.add(:zfs_master) do
  setcode do
    begin
      master_status = Facter.value('ip address show | grep -q secondary').instance_eval do 
      case master_status
      when ""
        false
      else
        true
    end
  end
end
