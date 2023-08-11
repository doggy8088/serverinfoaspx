<%@ Page Language="C#"
    Trace="false"
    Debug="true"
    CompilationMode="Always"
    CompilerOptions="/optimize+" %>

<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>
<%@ Import Namespace="System.Runtime.InteropServices" %>
<%@ Import Namespace="Microsoft.Win32" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="description" content="ASP.NET Host Info Script">
    <link rel="icon" href="data:;base64,iVBORw0KGgo=">
    <link rel="stylesheet" type="text/css" href="//maxcdn.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css" />
    <title>ASP.NET Host Info Script</title>
    <script runat="server">

        private string BoolIcon(object val)
        {
            val = (val ?? "false").ToString().ToLowerInvariant();
            return string.Format("<span class=\"glyphicon glyphicon-{0}\"></span>", Convert.ToBoolean(val) ? "ok" : "remove");
        }

        private bool HasInternetConnectivity()
        {
            try
            {
                return new WebClient().DownloadString("//maxcdn.bootstrapcdn.com/") != null;
            }
            catch { return false; }
        }

        private string HKLM_GetString(string path, string key)
        {
            string value = string.Empty;

            try
            {
                RegistryKey rk = Registry.LocalMachine.OpenSubKey(path);
                if (rk != null)
                {
                    value = rk.GetValue(key) as string;
                    rk.Close();
                }
            }
            catch
            {
                value = string.Empty;
            }

            return value;
        }

        public string FriendlyOsName()
        {
            string productName = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName");
            string csdVersion = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CSDVersion");
            if (productName != string.Empty)
            {
                return (productName.StartsWith("Microsoft") ? string.Empty : "Microsoft ") + productName + (csdVersion != string.Empty ? " " + csdVersion : string.Empty);
            }
            return string.Empty;
        }

        public Version GetIisVersion()
        {
            using (RegistryKey componentsKey = Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\InetStp", false))
            {
                if (componentsKey != null)
                {
                    int majorVersion = (int)componentsKey.GetValue("MajorVersion", -1);
                    int minorVersion = (int)componentsKey.GetValue("MinorVersion", -1);

                    if (majorVersion != -1 && minorVersion != -1)
                    {
                        return new Version(majorVersion, minorVersion);
                    }
                }
                return new Version(0, 0);
            }
        }

        private List<string> DotNetInstalled()
        {
            List<string> installed = new List<string>();
            string v;

            List<string> keys = new List<string>();
            //keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v1.1.4322");
            keys.Add(@"SOFTWARE\Microsoft\Active Setup\Installed Components\{78705f0d-e8db-4b2d-8193-982bdda15ecd}");

            foreach (string key in keys)
            {

                RegistryKey componentsKey = Registry.LocalMachine.OpenSubKey(key);
                if (componentsKey != null)
                {
                    if (key.Contains("v4"))
                    {
                        int rel = Convert.ToInt32(componentsKey.GetValue("Release"));
                        if (rel >= 378389)
                        {
                            installed.Add(".NET Framework 4.5");
                        }
                        else if (rel >= 378675)
                        {
                            installed.Add(".NET Framework 4.5.1");
                        }
                        else if (rel >= 379893)
                        {
                            installed.Add(".NET Framework 4.5.2");
                        }
                        else if (rel >= 378675)
                        {
                            installed.Add(".NET Framework 4.6");
                        }
                        else if (rel >= 394254)
                        {
                            installed.Add(".NET Framework 4.6.1");
                        }
                        else if (rel >= 394747)
                        {
                            installed.Add(".NET Framework 4.6.1");
                        }
                        else if (rel > 394747)
                        {
                            installed.Add(".NET Framework 4.6.?");
                        }
                    }
                    else
                    {
                        short installVal = Convert.ToInt16(componentsKey.GetValue("Install"));
                        short spVal = Convert.ToInt16(componentsKey.GetValue("SP"));
                        string versionVal = componentsKey.GetValue("Version") as string;


                        if (installVal == 1)
                        {
                            string cf = key.Contains(@"\Client") ? "Client Profile" : "";

                            if (spVal == 0)
                            {
                                v = string.Format(".NET {0} [{1}]", versionVal, cf).Replace("[]", string.Empty).Trim();
                            }
                            else
                            {
                                v = string.Format(".NET {0} (SP{1}) [{2}]", versionVal, spVal, cf).Replace("[]", string.Empty).Trim();
                            }

                            installed.Add(v);
                        }
                    }
                }
            }

            return installed;
        }

        private int CompareEndpoints(IPEndPoint ep1, IPEndPoint ep2)
        {
            return ep1.Port.CompareTo(ep2.Port);
        }

        private int CompareStrings(string s, string s1)
        {
            return s.ToLowerInvariant().CompareTo(s1.ToLowerInvariant());
        }

        /**/

        public class Tick
        {
            [DllImport("kernel32")]
            public static extern ulong GetTickCount64();

            public static TimeSpan GetUpTime()
            {
                return TimeSpan.FromMilliseconds(GetTickCount64());
            }
        }

        private enum EndpointType
        {
            Udp,
            Tcp
        }

        private class IPEndPointWithType : IPEndPoint
        {
            public IPEndPointWithType(IPEndPoint ep, EndpointType type)
                : base(ep.Address, ep.Port)
            {
                EndpointType = type;
            }

            public EndpointType EndpointType;// { get; private set;  }
        }

    </script>
</head>
<body role="document" style="font-family: 'Trebuchet MS', Tahoma, Arial;">
    <a role="link" id="home"></a>
    <div class="container" role="main">
        <br />
        <div class="panel panel-default">
            <div class="panel-heading">
                <h1><span class="glyphicon glyphicon-home" aria-hidden="true" style="font-size: 0.8em;"></span>&nbsp;<%= Environment.MachineName + " (" + Request.ServerVariables["LOCAL_ADDR"] + ")" %>
                </h1>
            </div>
            <div class="panel-body">
                <ol class="breadcrumb" style="font-size: 0.75em;">
                    <li class="breadcrumb-item">
                        <a href="#essentialInfo">Essential</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#process">Process</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#dotnetVersions">.NET</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#activeListeners">Ports</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#environmentVariables">Environment Vars</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#requestProperties">Request Props</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#requestHeaders">Request Headers</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#responseHeaders">Response Headers</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#serverVariables">Server Vars</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#session">Session</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="#gac">GAC</a>
                    </li>
                </ol>
                <div>
                    <a role="link" id="essentialInfo"></a>
                    <h3 class="text-primary">Essential Information</h3>
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>Server Name</td>
                                <td><%= Environment.MachineName %></td>
                            </tr>
                            <tr>
                                <td>Server IP</td>
                                <td><%= Request.ServerVariables["LOCAL_ADDR"] %></td>
                            </tr>
                            <tr>
                                <td>Operating System Name</td>
                                <td><%= FriendlyOsName() %></td>
                            </tr>
                            <tr>
                                <td>Operating System Version</td>
                                <td><%= Environment.OSVersion.VersionString %></td>
                            </tr>
                            <tr>
                                <td>Server Uptime</td>
                                <td>
                                    <%
                                        TimeSpan ts = Tick.GetUpTime();
                                        Response.Write(string.Format("{0}days {1}hrs {2}mins", ts.Days, ts.Hours, ts.Minutes));
                                    %>
                                </td>
                            </tr>
                            <tr>
                                <td>Processor Count</td>
                                <td><%= Environment.ProcessorCount %></td>
                            </tr>
                            <tr>
                                <td>Internet Access</td>
                                <td><%= BoolIcon(HasInternetConnectivity()) %></td>
                            </tr>
                            <tr>
                                <td>Internet Information Services (IIS) Version</td>
                                <td><%= GetIisVersion() %></td>
                            </tr>
                            <tr>
                                <td>IIS Using Integrated Pipeline</td>
                                <td><%= BoolIcon(HttpRuntime.UsingIntegratedPipeline) %></td>
                            </tr>
                            <tr>
                                <td>.Net Version (Current)</td>
                                <td><%= Environment.Version %></td>
                            </tr>
                            <tr>
                                <td>Current Time</td>
                                <td><%= DateTime.Now.ToString("F") + "<br/><span class=\"text-muted small\">" + TimeZone.CurrentTimeZone.StandardName %></td>
                            </tr>
                            <tr>
                                <td>Culture</td>
                                <td><%= CultureInfo.CurrentCulture.Name + " // " + CultureInfo.CurrentCulture.EnglishName %></td>
                            </tr>
                            <tr>
                                <td>UI Culture</td>
                                <td><%= CultureInfo.CurrentUICulture.Name + " // " + CultureInfo.CurrentUICulture.EnglishName %></td>
                            </tr>
                            <tr>
                                <td>System Directory</td>
                                <td><%= Environment.SystemDirectory %></td>
                            </tr>
                            <tr>
                                <td>Current User</td>
                                <td><%= Environment.UserDomainName + @"\" + Environment.UserName %></td>
                            </tr>
                            <tr>
                                <td>Physical App Path</td>
                                <td><% = Request.PhysicalApplicationPath %></td>
                            </tr>
                            <tr>
                                <td>Physical App Path is Writeable</td>
                                <td>
                                    <%

                                        string testFile = Path.Combine(Request.PhysicalApplicationPath, Environment.TickCount + ".txt");
                                        try
                                        {
                                            using (File.Create(testFile))
                                            {
                                                //
                                            }
                                            File.Delete(testFile);
                                            Response.Write(BoolIcon(true));
                                        }
                                        catch (UnauthorizedAccessException)
                                        {
                                            Response.Write(BoolIcon(false));
                                        }
                                        catch (Exception ex)
                                        {
                                            Response.Write(ex.Message);
                                        }
                                    %>
                                </td>
                            </tr>
                    </table>
                </div>

                <a role="link" id="process"></a>
                <div>
                    <h3 class="text-primary">Process<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Process Memory Usage (mb)</td>
                                <td><% = GC.GetTotalMemory(false)/1024/1024 %></td>
                            </tr>
                            <tr>
                                <td>Process Start Time</td>
                                <td><%= Process.GetCurrentProcess().StartTime.ToString("F") + "<br/><span class=\"text-muted small\">" + TimeZone.CurrentTimeZone.StandardName %></td>
                            </tr>
                            <tr>
                                <td>Process Total Processor Time</td>
                                <td>
                                    <% TimeSpan pcputs = Process.GetCurrentProcess().TotalProcessorTime;
                                        Response.Write(string.Format("{0}days {1}hrs {2}mins {3}secs", pcputs.Days, pcputs.Hours, pcputs.Minutes, pcputs.Seconds)); %>
                                </td>
                            </tr>
                            <tr>
                                <td>% Processor Time</td>
                                <td>
                                    <%
                                        double cpu = Process.GetCurrentProcess().TotalProcessorTime.TotalMilliseconds;
                                        double total = TimeSpan.FromTicks(DateTime.UtcNow.Ticks - Process.GetCurrentProcess().StartTime.ToUniversalTime().Ticks).TotalMilliseconds;

                                        Response.Write(Math.Round(cpu / total * 100, 2, MidpointRounding.AwayFromZero)); %>%
                                </td>
                            </tr>
                            <tr>
                                <td>Process Threads</td>
                                <td><%= Process.GetCurrentProcess().Threads.Count %></td>
                            </tr>
                    </table>
                </div>

                <a role="link" id="dotnetVersions"></a>
                <div>
                    <h3 class="text-primary">
                        .NET<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                </div>

<%--                <div class="pull-left" style="width: 50%;">

                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Version (derived from filesystem)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string runtimeRoot = new DirectoryInfo(RuntimeEnvironment.GetRuntimeDirectory()).Parent.FullName;
                                string[] versions = Directory.GetDirectories(runtimeRoot, "v*");
                                string version = "Unknown";

                                for (int i = 0; i < versions.Length; i++)
                                {
                                    int startIndex = versions[i].LastIndexOf("\\") + 2;
                                    version = versions[i].Substring(startIndex, versions[i].Length - startIndex);
                                    if (version.Contains("."))
                                    {
                                        string sys = Path.Combine(versions[i], "csc.exe");
                                        //FileInfo f= new FileInfo(sys);
                                        if (File.Exists(sys))
                                        {
                                            string v = FileVersionInfo.GetVersionInfo(sys).ProductVersion;

                                            Response.Write(string.Format("<tr><td>{0}</td></tr>", v));
                                        }
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>--%>

                <div class="pull-left" style="width: 50%;">
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Version (derived from registry)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] versions2 = DotNetInstalled().ToArray();
                                string version2 = "Unknown";

                                for (int i = versions2.Length - 1; i >= 0; i--)
                                {
                                    int startIndex = versions2[i].LastIndexOf("\\") + 2;
                                    version2 = versions2[i].Substring(startIndex, versions2[i].Length - startIndex);
                                    if (version2.Contains("."))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td></tr>", version2));
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
                <div class="clearfix"></div>

                <a role="link" id="activeListeners"></a>
                <div>
                    <h3 class="text-primary">Active Listeners<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Address</th>
                                <th>TCP</th>
                                <th>UDP</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] serviceLines = null;
                                if (File.Exists(@"C:\Windows\System32\drivers\etc\services"))
                                {
                                    serviceLines = File.ReadAllLines(@"C:\Windows\System32\drivers\etc\services");
                                }
                                IPGlobalProperties properties = IPGlobalProperties.GetIPGlobalProperties();
                                List<IPEndPointWithType> endpoints = new List<IPEndPointWithType>();

                                string getActiveListenersError = null;
                                try
                                {
                                    foreach (IPEndPoint ep in properties.GetActiveTcpListeners())
                                    {
                                        endpoints.Add(new IPEndPointWithType(ep, EndpointType.Tcp));
                                    }
                                    foreach (IPEndPoint ep in properties.GetActiveUdpListeners())
                                    {
                                        endpoints.Add(new IPEndPointWithType(ep, EndpointType.Udp));
                                    }
                                }
                                catch (Exception ex)
                                {
                                    getActiveListenersError = ex.Message;
                                }

                                if (getActiveListenersError != null && getActiveListenersError.Trim().Length > 0)
                                {
                                    Response.Write(string.Format("<tr><td colspan=\"3\">{0}</td></tr>", getActiveListenersError));
                                }


                                endpoints.Sort(CompareEndpoints);

                                foreach (IPEndPointWithType ep in endpoints)
                                {
                                    if (ep.Address.ToString() != "127.0.0.1")
                                    {
                                        string portName = Array.Find(serviceLines, delegate (string s) { return s.Contains(string.Format("{0}/{1}", ep.Port, ep.EndpointType.ToString().ToLowerInvariant())); });
                                        if (portName != null)
                                        {
                                            portName = portName.Substring(0, portName.IndexOf(' '));
                                        }
                                        else
                                        {
                                            portName = string.Empty;
                                        }

                                        if (ep.EndpointType == EndpointType.Tcp)
                                        {
                                            Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td><td></td><td>{2}</td></tr>", ep.Address, ep.Port, portName));
                                        }
                                        else
                                        {
                                            Response.Write(string.Format("<tr><td>{0}</td><td></td><td>{1}</td><td>{2}</td></tr>", ep.Address, ep.Port, portName));
                                        }
                                    }
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="environmentVariables"></a>
                <div>
                    <h3 class="text-primary">Environment Variables<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Environment.GetEnvironmentVariables().Keys)
                                {
                                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Environment.GetEnvironmentVariable(key) ?? "").Replace(";", "<br/>")));
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="requestProperties"></a>
                <div>
                    <h3 class="text-primary">Request Properties<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "ApplicationPath", Request.ApplicationPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "AppRelativeCurrentExecutionFilePath", Request.AppRelativeCurrentExecutionFilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "CurrentExecutionFilePath", Request.CurrentExecutionFilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "FilePath", Request.FilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Path", Request.Path));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "HttpMethod", Request.HttpMethod));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "IsSecureConnection", BoolIcon(Request.IsSecureConnection)));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "LogonUserIdentity", Request.LogonUserIdentity.Name));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "PhysicalApplicationPath", Request.PhysicalApplicationPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "PhysicalPath", Request.PhysicalPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Url", Request.Url));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "UserAgent", Request.UserAgent));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "UserHostAddress", Request.UserHostAddress));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "UserHostName", Request.UserHostName));
                            %>
                    </table>
                </div>

                <a role="link" id="requestHeaders"></a>
                <div>
                    <h3 class="text-primary">Request Headers<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Request.Headers.AllKeys)
                                {
                                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Request.Headers[key] ?? "").Trim()));
                                }
                            %>
                    </table>
                </div>


                <% if (HttpRuntime.UsingIntegratedPipeline)
                    {
                %>
                <a role="link" id="responseHeaders"></a>
                <div>
                    <h3 class="text-primary">Response Headers<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Response.Headers.AllKeys)
                                {
                                    string headerValue = Response.Headers[key];
                                    if (!string.IsNullOrEmpty(headerValue))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, Response.Headers[key] ?? ""));
                                    }
                                }
                            %>
                    </table>
                </div>
                <% } %>

                <a role="link" id="serverVariables"></a>
                <div>
                    <h3 class="text-primary">Request Server Variables<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Request.ServerVariables.AllKeys)
                                {
                                    string headerValue = Request.ServerVariables[key];
                                    if (!string.IsNullOrEmpty(headerValue))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Request.ServerVariables[key] ?? "").Trim()));
                                    }
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="session"></a>
                <% if (HttpContext.Current.Session != null)
                    { %>
                <div>
                    <h3 class="text-primary">Session<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>SessionID</td>
                                <td><%= Session.SessionID %></td>
                            </tr>
                            <tr>
                                <td>CodePage</td>
                                <td><%= Session.CodePage + " [" + Encoding.GetEncoding(Session.CodePage, new EncoderExceptionFallback(), new DecoderExceptionFallback()).EncodingName + "]" %></td>
                            </tr>
                            <tr>
                                <td>CookieMode</td>
                                <td><%= Session.CookieMode.ToString() %></td>
                            </tr>
                            <tr>
                                <td>Item Count</td>
                                <td><%= Session.Count.ToString() %></td>
                            </tr>
                            <tr>
                                <td>IsCookieless</td>
                                <td><%= BoolIcon(Session.IsCookieless) %></td>
                            </tr>
                            <tr>
                                <td>IsNewSession</td>
                                <td><%= BoolIcon(Session.IsNewSession) %></td>
                            </tr>
                            <tr>
                                <td>IsReadOnly</td>
                                <td><%= BoolIcon(Session.IsReadOnly) %></td>
                            </tr>
                            <tr>
                                <td>IsSynchronized</td>
                                <td><%= BoolIcon(Session.IsSynchronized) %></td>
                            </tr>
                            <tr>
                                <td>LCID</td>
                                <td><%= Session.LCID + " [" + new CultureInfo(Session.LCID).EnglishName + "]" %></td>
                            </tr>
                            <tr>
                                <td>Mode</td>
                                <td><%= Session.Mode.ToString() %></td>
                            </tr>
                            <tr>
                                <td>Timeout</td>
                                <td><%= Session.Timeout.ToString() %></td>
                            </tr>
                            <%
                                foreach (string key in Session.Keys)
                                {
                                    string sessionValue = Session[key].ToString();
                                    if (!string.IsNullOrEmpty(sessionValue))
                                    {
                                        Response.Write(string.Format("<tr><td>Session[\"{0}\"]</td><td>{1}</td></tr>", key, sessionValue));
                                    }
                                }
                            %>
                    </table>
                </div>
                <% }
                else
                { %>
                <div>
                    <h3 class="text-primary">Session<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>Session is turned OFF</td>
                            </tr>

                    </table>
                </div>
                <% }
                %>
                <a role="link" id="gac"></a>
                <div>
                    <h3 class="text-primary">Global Assembly Cache (GAC)<a href="#home" class="pull-right">
                        <span class="glyphicon glyphicon-arrow-up small"></span></a>
                    </h3>
                    <table class="table table-striped">
                        <tbody>
                            <% try
                                {
                                    string windows = Environment.GetEnvironmentVariable("SystemRoot");
                                    if (windows != null)
                                    {
                                        string assembly = Path.Combine(windows, @"assembly");
                                        string[] gacFolders = Directory.GetDirectories(assembly);

                                        List<string> allAssemblies = new List<string>();
                                        foreach (string folder in gacFolders)
                                        {
                                            if (folder.ToLowerInvariant().Contains("\\gac"))
                                            {
                                                string path = Path.Combine(assembly, folder);
                                                if (Directory.Exists(path))
                                                {
                                                    string[] assemblyFolders = Directory.GetDirectories(path);

                                                    if (assemblyFolders.Length <= 0) continue;
                                                    foreach (string assemblyFolder in assemblyFolders)
                                                    {
                                                        if (!allAssemblies.Contains(assemblyFolder))
                                                        {
                                                            allAssemblies.Add(assemblyFolder);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        allAssemblies.Sort(CompareStrings);

                                        List<string> assemblyInfo = new List<string>();

                                        foreach (string dll in allAssemblies)
                                        {
                                            FileInfo[] dlls = new DirectoryInfo(dll).GetFiles("*.dll", SearchOption.AllDirectories);
                                            foreach (FileInfo fi in dlls)
                                            {
                                                if (fi.FullName.Contains("__"))
                                                {
                                                    string dir = fi.FullName.Replace(dll + @"\", "");
                                                    dir = dir.Substring(0, dir.IndexOf('\\'));

                                                    assemblyInfo.Add(fi.Name + "~" + dir.Replace("__", "~"));
                                                }
                                            }
                                        }

                                        assemblyInfo.Sort(CompareStrings);

                                        foreach (string dllInfo in assemblyInfo)
                                        {
                                            string[] parts = dllInfo.Split('~');

                                            string dll = parts[0];
                                            string dllVersion = parts[1];
                                            string dllKey = parts[2];

                                            string asmString = string.Format("{2}, Version={0}, PublicKeyToken={1}", dllVersion, dllKey, dll);
                                            Response.Write(string.Format("<tr><td><a href=\"https://startpage.com/do/search?query={0}.dll\" target=\"_blank\"><span class=\"glyphicon glyphicon-new-window small\"></span>&nbsp;{0}</a><br/>{1}</td></tr>", dll.Replace(".dll", string.Empty), asmString));
                                        }
                                    }
                                }
                                catch (NotSupportedException ex)
                                {
                                    Response.Write(ex.Message);
                                }
                            %>
                    </table>
                </div>
            </div>

            <div class="panel-footer">
                <span class="text-muted"><span class="glyphicon glyphicon-info-sign" aria-hidden="true"></span>The latest version can be found <a href="https://github.com/doggy8088/serverinfoaspx/blob/main/serverinfo.aspx" target="_blank"><span class="glyphicon glyphicon-new-window small"></span>here</a>. Please raise bugs, issues and functionality requests <a href="https://github.com/doggy8088/serverinfoaspx/issues" target="_blank"><span class="glyphicon glyphicon-new-window small"></span>here</a>.</span>
            </div>
        </div>
    </div>
</body>
</html>
