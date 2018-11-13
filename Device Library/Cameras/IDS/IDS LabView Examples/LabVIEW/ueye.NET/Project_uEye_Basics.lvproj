<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="17008000">
	<Item Name="Mein Computer" Type="My Computer">
		<Property Name="NI.SortType" Type="Int">3</Property>
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">Mein Computer/VI-Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">Mein Computer/VI-Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="uEye_Basics.vi" Type="VI" URL="../Examples/uEye_Basics.vi"/>
		<Item Name="Abhängigkeiten" Type="Dependencies">
			<Item Name="System.Windows.Forms" Type="Document" URL="System.Windows.Forms">
				<Property Name="NI.PreserveRelativePath" Type="Bool">true</Property>
			</Item>
			<Item Name="SubVI_Example_GetImageSize.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_GetImageSize.vi"/>
			<Item Name="SubVI_Example_MemoryAllocation.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_MemoryAllocation.vi"/>
			<Item Name="SubVI_Example_CameraInit.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_CameraInit.vi"/>
			<Item Name="Error_Handling.vi" Type="VI" URL="../Library/Error_Handling.vi"/>
			<Item Name="uEyeDotNet.dll" Type="Document" URL="../uEyeDotNet.dll"/>
		</Item>
		<Item Name="Build-Spezifikationen" Type="Build"/>
	</Item>
</Project>
