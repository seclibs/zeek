// See the file  in the main distribution directory for copyright.

#include "Modbus.h"
#include "plugin/Plugin.h"
#include "analyzer/Component.h"

namespace plugin {
namespace Zeek_Modbus {

class Plugin : public plugin::Plugin {
public:
	plugin::Configuration Configure() override
		{
		AddComponent(new ::analyzer::Component("MODBUS", ::analyzer::modbus::ModbusTCP_Analyzer::Instantiate));

		plugin::Configuration config;
		config.name = "Zeek::Modbus";
		config.description = "Modbus analyzer";
		return config;
		}
} plugin;

}
}
