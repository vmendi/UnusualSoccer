using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;

namespace ServerCommon
{
    // Como queremos leer la cadena de conexion desde el web.config, hacemos esta pequeña partial... Asi el resto del codigo
    // puede seguir haciendo un new del constructor sin parametros.
    public partial class SoccerDataModelDataContext
    {
        public SoccerDataModelDataContext() : this(ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString)
        {
        }
    }
}
