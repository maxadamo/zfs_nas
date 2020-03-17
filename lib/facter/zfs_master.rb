Facter.add(:zfs_master) do
  setcode do
    begin
      Facter::Core::Execution.execute('ip address show | grep -q secondary')
      true
    rescue Facter::Core::Execution::ExecutionFailure
      undef
    end
  end
end
