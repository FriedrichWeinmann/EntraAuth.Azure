class ServiceTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute {
	[object] Transform([System.Management.Automation.EngineIntrinsics] $Intrinsics, [object] $InputData) {
		if ($null -eq $InputData) {
			return @{ Azure = 'Azure' }
		}
		if ($InputData -is [hashtable]) {
			return $InputData
		}
		if ($InputData -is [ordered]) {
			return $InputData
		}
		if ($InputData -is [string]) {
			return @{ Azure = $InputData }
		}
		if ($InputData.Azure) {
			$map = @{ }
			if ($InputData.Azure) { $map.Azure = $InputData.Azure }
			return $map
		}
		return @{ Graph = $InputData -as [string] }
	}
}