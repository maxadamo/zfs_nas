Facter.add(:zfs_master) do
  setcode do
    begin
      masterstatus = Facter.value('ip address show | grep secondary').instance_eval do
        if masterstatus.include? "secondary"
          true
        else
          false
        end
      end
    end
  end
end
