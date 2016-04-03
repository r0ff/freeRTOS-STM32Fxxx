import qbs 1.0
import qbs.FileInfo

Product
{
	type: ["application", "hex", "bin", "size", "listing"]

	Depends { name:"cpp" }
	name: 'freeRTOS-STM32Fxxx' + '_' + ver

	property int version_major: 0
	property int version_minor: 1
	property int version_build: 0
	property int version_release: 0

	property string ver:
	{
		var str_version = [];

		str_version.push(version_major);
		str_version.push(version_minor);

		if( version_release > 0 || version_build > 0 )
			str_version.push( version_build )

		if( version_release > 0 )
			str_version.push( version_release )

		return str_version.join('_')
	}

	property string m_stm32f2xxCubeVersion:
	{
		var major = 1;
		var minor = 3;
		var micro = 0;
		var nano  = 0;

		var out = [];
		out.push(major); out.push(minor); out.push(micro);

		if (nano > 0)
		{
			out.push(nano);
		}

		return 'F2_V' + out.join('.');
	}

	property string m_stm32f4xxCubeVersion:
	{
		var major = 1;
		var minor = 10;
		var micro = 0;
		var nano  = 0;

		var out = [];
		out.push(major); out.push(minor); out.push(micro);

		if (nano > 0)
		{
			out.push(nano);
		}

		return 'F4_V' + out.join('.');
	}

	property string stm2_family: 'stm32f2'
	property string stm4_family: 'stm32f4'
	property string stm2_prefix: stm2_family
	property string stm4_prefix: stm4_family + "29"
	property string stm2: stm2_prefix + "xx"
	property string stm4: stm4_prefix + "xx"
	property string libs:
	{
		return '../../STM32Cube_FW_' +
		    (stm_family == stm4_family? m_stm32f4xxCubeVersion: m_stm32f2xxCubeVersion) +
		    '/Drivers';
	}
	property string stm_family: stm4_family
	property string stm_prefix: stm4_prefix // выбором префикса настраиваются все пути
	property string chip: stm_prefix + 'xx'
	property string cmsis: libs + '/CMSIS'
	property string system: cmsis + '/Device/ST/' + stm_prefix.toUpperCase() + 'xx'
	property string hal: libs + '/' + stm_prefix.toUpperCase() + 'xx' + '_StdPeriph_Driver'
	property string mlib: libs + "/STM_My_Lib"

	cpp.positionIndependentCode: false

	Properties
	{
		condition: chip === stm2
		cpp.defines:
		[
			chip.toUpperCase(), //дефайнами настраиваем cmsis на нашу плату
			"USE_STDPERIPH_DRIVER",
			'SYSTEM_CAN1',
			'SYSTEM_CAN_FIFO0',
			"HSE_VALUE=24000000",
		]
	}

	Properties
	{
		condition: chip === stm4
		cpp.defines:
		[
			"TOOLCHAIN_GCC_CW=1",
			stm_prefix.toUpperCase() + 'xx', //дефайнами настраиваем cmsis на нашу плату
			"USE_STDPERIPH_DRIVER",
			"HSE_VALUE=8000000",
		]
	}

	property stringList compiler_flags:
	[
		"-c",
		"-mthumb",
		"-std=gnu11",
		"-fno-strict-aliasing",
		"-ffunction-sections",
		"-fdata-sections",
		'-Wno-unused-parameter',
	]

	cpp.commonCompilerFlags:
	{
		var flag = compiler_flags

		switch( chip )
		{
		case stm2: flag = flag.concat("-mcpu=cortex-m3", "-mfix-cortex-m3-ldrd",
									  "-msoft-float",    "-fno-hosted",
									  "-mno-sched-prolog" ); break

		case stm4: flag = flag.concat("-mcpu=cortex-m4", "-mabi=aapcs",
									  "-mfloat-abi=hard","-flto",
									  "-fno-builtin" ); break
		}

		return flag
	}

	cpp.optimization:
	{
		return (qbs.buildVariant == 'release'? 'fast': 'none')
	}

	cpp.linkerScripts:
	{
		if( chip == stm2 )
		{
			return path + ( qbs.buildVariant == 'debug'?
								"/startup/stm32f205ve_debug.ld" :
								"/startup/stm32f205ve.ld" )
		}

		return path + "/startup/STM32F429ZI_FLASH.ld"
	}

	Properties
	{
		condition: chip == stm2

		cpp.linkerFlags:
		[

			"-mthumb",
			"-mcpu=cortex-m3",
			"-mfix-cortex-m3-ldrd",
			"-specs=nano.specs",
			"-Wl,--gc-sections",
		]
	}

	Properties
	{
		condition: chip == stm4

		cpp.linkerFlags:
		[
			"-mthumb",
			"-mcpu=cortex-m4",
			"-mfloat-abi=hard",
			"-mfpu=fpv4-sp-d16",
			"-specs=nano.specs",
			"-Wl,--gc-sections",
		]
	}

	cpp.includePaths:
	[
//		path + "/run/inc/",
//		system + "/Include/",
//		hal + "/inc/",
//		mlib + "/inc/",
		cmsis + "/Include/",
		cmsis + '/Device/ST/' + stm_family.toUpperCase() + 'xx/Include',
	]

	files:
	[
		"main.c",
//		path + "/run/src/*.c",
	]

	Group
	{
		name: "system"

		files:
		[
			path + "/startup/system_" + stm_family + "xx.c",
			path + "/startup/startup_" + stm_prefix + (chip == stm2? "xx.S": "xx.S"),
			cpp.linkerScripts[0]
		]
	}

//	Group
//	{
//		name: "hal"
//		files:
//		[
//			hal + "/src/misc.c",
//			hal + "/src/" + stm_prefix + "xx_can.c",
//			hal + "/src/" + stm_prefix + "xx_gpio.c",
//			hal + "/src/" + stm_prefix + "xx_rcc.c",
//			hal + "/src/" + stm_prefix + "xx_tim.c",
//		]
//	}

//	Group
//	{
//		name: "mylib"
//		files:
//		[
//			mlib + "/src/str_convert.c",
//			mlib + '/src/CsCanHandle.c',
//		]
//	}

//	Group
//	{
//		name: "headers"
//		files:
//		[
//			system + "/Include/*.h",
//			hal + "/inc/*.h",
//			mlib + "/inc/*.h",
//			cmsis + "/Include/*.h",
//			path + "/run/inc/*.h",
//		]
//	}

	Rule
	{
		id: hex
		inputs: "application"
		Artifact {
			fileTags: ["hex"]
			filePath: FileInfo.baseName(input.filePath) + ".hex"
		}
		prepare: {
			var args = ["-O", "ihex", input.filePath, output.filePath];
			var cmd = new Command("arm-none-eabi-objcopy", args);
			cmd.description = "converting to hex: "+FileInfo.fileName(input.filePath);
			cmd.highlight = "linker";
			return cmd;
		}
	}

	Rule
	{
		id: bin
		inputs: "application"
		Artifact {
			fileTags: ["bin"]
			filePath: FileInfo.baseName(input.filePath) + ".bin"
		}
		prepare: {
			var args = ["-O", "binary", input.filePath, output.filePath];
			var cmd = new Command("arm-none-eabi-objcopy", args);
			cmd.description = "converting to bin: "+FileInfo.fileName(input.filePath);
			cmd.highlight = "linker";
			return cmd;
		}
	}

	Rule
	{
		id: listing
		inputs: "application"
		condition: false
		Artifact
		{
			fileTags: ["listing"]
			filePath: FileInfo.baseName(input.filePath) + ".lst"
		}
		prepare:
		{
			var args = ['-S', '-j.isr_vector', '-j.text', input.filePath];
			var cmd = new Command("arm-none-eabi-objdump", args);
			cmd.description = "generate listing from: " + FileInfo.fileName(input.filePath);
			cmd.highlight = "linker";
			return cmd;
		}
	}

	Rule
	{
		id: size
		inputs: "application"
		Artifact
		{
			fileTags: ["size"]
			filePath: "-"
		}
		prepare:
		{
			var args = [input.filePath];
			var cmd = new Command("arm-none-eabi-size", args);
			cmd.description = "File size: " + FileInfo.fileName(input.filePath);
			cmd.highlight = "linker";
			return cmd;
		}
	}
}
