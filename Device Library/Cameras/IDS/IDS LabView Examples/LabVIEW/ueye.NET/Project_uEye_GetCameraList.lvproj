<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="10008000">
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
		<Item Name="uEye_GetCameraList.vi" Type="VI" URL="../Examples/uEye_GetCameraList.vi"/>
		<Item Name="Abhängigkeiten" Type="Dependencies">
			<Item Name="instr.lib" Type="Folder">
				<Item Name="uEyeDotNet.dll" Type="Document" URL="/&lt;instrlib&gt;/IDS/ueye.NET/uEyeDotNet.dll"/>
			</Item>
		</Item>
		<Item Name="Build-Spezifikationen" Type="Build"/>
	</Item>
</Project>
