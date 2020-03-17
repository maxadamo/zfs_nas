Facter.add(:zfs_master) do
  setcode do
    begin
      masterstatus = Facter::Util::Resolution.exec("ip address show | grep secondary")
      if masterstatus =~ /secondary/
        true
      else
        false
      end
    end
  end
end
