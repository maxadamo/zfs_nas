Facter.add(:zfs_master) do
  setcode do
    begin
      master_status = Facter.value('ip address show | grep secondary').instance_eval do
        if master_status.include? "secondary"
          true
        else
          false
        end
      end
    end
  end
end
