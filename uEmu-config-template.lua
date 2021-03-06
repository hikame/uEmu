--[[
This is a bare minimum S2E config file to demonstrate the use of libs2e with PyKVM.
Please refer to the S2E documentation for more details.
This file was automatically generated at {{ creation_time }}
]]--

s2e = {
    logging = {
        -- Possible values include "all", "debug", "info", "warn" and "none".
        -- See Logging.h in libs2ecore.
        console = "{{ loglevel }}",
        logLevel = "{{ loglevel }}",
    },
    -- All the cl::opt options defined in the engine can be tweaked here.
    -- This can be left empty most of the time.
    -- Most of the options can be found in S2EExecutor.cpp and Executor.cpp.
    kleeArgs = {
		"--verbose-on-symbolic-address=true",
		"--verbose-state-switching=true",
		"--verbose-fork-info=true",
		"--print-mode-switch=false",
		"--fork-on-symbolic-address=false",--no self-modifying code and load libs for IoT firmware
		"--suppress-external-warnings=true"
    },
}

--rom start should be equal to vtor
mem = {
	rom = {
		{% for ro in rom %} {{ '{' }}{{ ro }}{{ '}' }}, {% endfor %}
	},
	ram = {
		{% for ra in ram %} {{ '{' }}{{ ra }}{{ '}' }}, {% endfor %}
	},
}

init = {
   entry = {{ entry }}, -- equal to pc of Reset_Handler+1
   msp_init = {{ msp }},
   vtor = {{ vtor }},
}

-- Declare empty plugin settings. They will be populated in the rest of
-- the configuration file.
plugins = {}
pluginsConfig = {}

-- Include various convenient functions
dofile('library.lua')

-------------------------------------------------------------------------------
-- This plugin contains the core custom instructions.
-- Some of these include s2e_make_symbolic, s2e_kill_state, etc.
-- You always want to have this plugin included.

add_plugin("BaseInstructions")

add_plugin("Vmi")
pluginsConfig.Vmi = {
    baseDirs = {
        "{{ pwd }}"
    }
}

add_plugin("RawMonitor")
-- The custom instruction will notify RawMonitor of all newly loaded modules
pluginsConfig.RawMonitor = {

    kernelStart = 0x00000000,
}

-------------------------------------------------------------------------------
-- Keeps for each state/process an updated map of all the loaded modules.
add_plugin("ModuleMap")
pluginsConfig.ModuleMap = {

    logLevel="{{ loglevel }}"
}
-------------------------------------------------------------------------------
-- Tracks execution of specific modules.
-- Analysis plugins are often interested only in small portions of the system,
-- typically the modules under analysis. This plugin filters out all core
-- events that do not concern the modules under analysis. This simplifies
-- code instrumentation.
-- Instead of listing individual modules, you can also track all modules by
-- setting configureAllModules = true

add_plugin("ModuleExecutionDetector")
pluginsConfig.ModuleExecutionDetector = {

    trackExecution=true,
    logLevel="{{ loglevel }}"
}

{% if loglevel == "debug" %}
-------------------------------------------------------------------------------
-- This is the main execution tracing plugin.
-- It generates the ExecutionTracer.dat file in the s2e-last folder.
-- That files contains trace information in a binary format. Other plugins can
-- hook into ExecutionTracer in order to insert custom tracing data.
--
-- This is a core plugin, you most likely always want to have it.

add_plugin("ExecutionTracer")

-------------------------------------------------------------------------------
-- This plugin records events about module loads/unloads and stores them
-- in ExecutionTracer.dat.
-- This is useful in order to map raw program counters and pids to actual
-- module names.

add_plugin("ModuleTracer")

add_plugin("StateSwitchTracer")

{% endif %}

add_plugin("ARMFunctionMonitor")
pluginsConfig.ARMFunctionMonitor = {
	functionParameterNum = {{ function_parameter_num }},
	callerLevel = {{ caller_level }},
}

add_plugin("PeripheralModelLearning")
pluginsConfig.PeripheralModelLearning = {
	useKnowledgeBase = {{ mode }},
	useFuzzer = {{ enable_fuzz }},
	limitSymNum = {{ limit_symbolic_count_t3 }},
	maxT2Size = {{ max_t2_size }},
	{% if enable_fuzz == "true" %}allowNewPhs = {{ allow_new_phs }},
	{% else %}allowNewPhs = true,{% endif %}
	{% if mode == "true" %}autoModeSwitch = {{ allow_auto_mode_switch }},
	{% else %}autoModeSwitch = false,{% endif %}
	enableExtendedInterruptMode = {{ enable_extended_irq }},
	cacheFileName = "{{ cache_file_name }}",
	firmwareName = "{{ firmware_name }}",
}

{% if mode == "true" %}
add_plugin("AFLFuzzer")
pluginsConfig.AFLFuzzer = {
	useAFLFuzzer = {{ enable_fuzz }},
    {% if enable_fuzz == "true" %}	
	inputPeripherals = {
		{% for input_peripheral in input_peripherals %} {{ '{' }}{{ input_peripheral }}{{ '}' }}, {% endfor %}
	},
	writeRanges = {
		{% for writeable_range in writeable_ranges %} {{ '{' }}{{ writeable_range }}{{ '}' }}, {% endfor %}
	},
	crashPoints = {
        {% for k in crash_points %}
        {{ k }},{% endfor %}
	},
	hangTimeout = {{ time_out }},
	forkCount = {{ fork_count }},
	{% endif %}
}
{% endif %}

add_plugin("InvalidStatesDetection")
pluginsConfig.InvalidStatesDetection = {
	usePeripheralCache = {{ mode }},
	bb_inv1 = {{ bb_inv1 }},
	bb_inv2 = {{ bb_inv2 }},
	bb_terminate = {{ bb_terminate }},
	tbInterval = {{ irq_tb_break }},
	killPoints = {
        {% for k in kill_points %}
        {{ k }},{% endfor %}
	},
	alivePoints = {
        {% for a in alive_points %}
        {{ a }},{% endfor %}
	}
}

add_plugin("ExternalInterrupt")
pluginsConfig.ExternalInterrupt ={
	BBScale= {{ bb_terminate }},
	disableSystickInterrupt = {{ disable_systick }},
	disableIrqs = {
        {% for i in disable_irqs %}
        {{ i }},{% endfor %}
	},
	tbInterval = {{ irq_tb_break }},
	{% if disable_systick == "true" %}systickBeginPoint = {{ systick_begin_point }},{% endif %}
}

