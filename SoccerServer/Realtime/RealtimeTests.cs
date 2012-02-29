﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NetEngine;

namespace Realtime
{
    public partial class RealtimeLobby
    {
        public string TestMethod01(NetPlug src, string input)
        {
            if (input != "TestMethod01Input")
                return "FAILED";

            return "TestMethod01Return";
        }

        public void TestMethod02(NetPlug src, float input)
        {
            if (input != 666.666f)
                Log.Error("TestMethod02");
        }

        public string TestMethod03(NetPlug src)
        {
            string ret = "";

            for (int c = 0; c < 666; c++)
                ret += "-";

            return ret;
        }

        public string TestMethod04(NetPlug src)
        {
            return src.ID.ToString();
        }
    }
}