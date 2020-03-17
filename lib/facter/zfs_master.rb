Facter.add(:zfs_master) do
  setcode do
    begin
      Facter::Core::Execution.execute('ip address show | grep secondary')
      true
    rescue Facter::Core::Execution::ExecutionFailure
      false
    end
  end
end
