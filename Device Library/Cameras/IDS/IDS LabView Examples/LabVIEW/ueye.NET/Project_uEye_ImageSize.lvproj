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
		<Item Name="uEye_ImageSize.vi" Type="VI" URL="../Examples/uEye_ImageSize.vi"/>
		<Item Name="Abhängigkeiten" Type="Dependencies">
			<Item Name="instr.lib" Type="Folder">
				<Item Name="Error_Handling.vi" Type="VI" URL="../Library/Error_Handling.vi"/>
				<Item Name="SubVI_Example_GetImageSize.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_GetImageSize.vi"/>
				<Item Name="SubVI_Example_MemoryAllocation.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_MemoryAllocation.vi"/>
				<Item Name="SubVI_Example_CameraInit.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_CameraInit.vi"/>
				<Item Name="ArrayToImage.vi" Type="VI" URL="../Library/ArrayToImage.vi"/>
				<Item Name="SubVI_Example_Is_XS.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_Is_XS.vi"/>
				<Item Name="SubVI_Example_Init_Camera_Error_Handling.vi" Type="VI" URL="../Examples/Example Modules SubVIs/SubVI_Example_Init_Camera_Error_Handling.vi"/>
				<Item Name="uEyeDotNet.dll" Type="Document" URL="/&lt;instrlib&gt;/IDS/ueye.NET/uEyeDotNet.dll"/>
			</Item>
			<Item Name="vi.lib" Type="Folder">
				<Item Name="FixBadRect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pictutil.llb/FixBadRect.vi"/>
				<Item Name="imagedata.ctl" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/imagedata.ctl"/>
				<Item Name="Draw Flattened Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw Flattened Pixmap.vi"/>
				<Item Name="Flatten Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/pixmap.llb/Flatten Pixmap.vi"/>
				<Item Name="Draw True-Color Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw True-Color Pixmap.vi"/>
				<Item Name="Draw 1-Bit Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw 1-Bit Pixmap.vi"/>
				<Item Name="Draw 8-Bit Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw 8-Bit Pixmap.vi"/>
				<Item Name="Draw 4-Bit Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw 4-Bit Pixmap.vi"/>
				<Item Name="Draw Unflattened Pixmap.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Draw Unflattened Pixmap.vi"/>
			</Item>
		</Item>
		<Item Name="Build-Spezifikationen" Type="Build"/>
	</Item>
</Project>
