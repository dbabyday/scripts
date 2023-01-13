SET NOCOUNT ON;

        -- user input
DECLARE @Bookmarks NVARCHAR(MAX) = N'{
   "checksum": "3dc6c97f8221ab2acf9f779166c098b6",
   "roots": {
      "bookmark_bar": {
         "children": [ {
            "date_added": "13103655308683993",
            "id": "6",
            "meta_info": {
               "last_visited_desktop": "13140289482127789"
            },
            "name": "CONNECT",
            "type": "url",
            "url": "https://connect.plexus.com/SitePages/Connect.aspx"
         }, {
            "date_added": "13097100746941036",
            "id": "8",
            "meta_info": {
               "last_visited_desktop": "13140283434231223"
            },
            "name": "ServiceNow",
            "type": "url",
            "url": "https://plexus.service-now.com/navpage.do"
         }, {
            "date_added": "13097100746956636",
            "id": "12",
            "meta_info": {
               "last_visited_desktop": "13139593241927217"
            },
            "name": "SQL Monitor",
            "type": "url",
            "url": "http://gcc-sql-pd-001:8081/"
         }, {
            "date_added": "13097100743930236",
            "id": "20",
            "name": "AppsToGo",
            "type": "url",
            "url": "https://appstogo.plexus.com/"
         }, {
            "date_added": "13097100746769436",
            "id": "10",
            "name": "CyberArk",
            "type": "url",
            "url": "https://vault.plexus.com/PasswordVault/logon.aspx?ReturnUrl=%2fPasswordVault%2fdefault.aspx"
         }, {
            "date_added": "13097100747081436",
            "id": "18",
            "name": "vSphere",
            "type": "url",
            "url": "https://vsphere.na.plexus.com:9443/vsphere-client/"
         }, {
            "date_added": "13134500525548068",
            "id": "71",
            "meta_info": {
               "last_visited_desktop": "13140040349493313"
            },
            "name": "vSphere 6.0 - Dev",
            "type": "url",
            "url": "https://dcc-vc-comp-001.na.plexus.com/vsphere-client/?csp"
         }, {
            "date_added": "13097100746894236",
            "id": "14",
            "meta_info": {
               "last_visited_desktop": "13140130899548287"
            },
            "name": "Outage Calendar",
            "type": "url",
            "url": "https://connect.plexus.com/sites/IT/GITSD/_layouts/15/start.aspx#/Outage%20Calendars/Forms/AllItems.aspx"
         }, {
            "date_added": "13097100746785036",
            "id": "15",
            "meta_info": {
               "last_visited_desktop": "13140040951610179"
            },
            "name": "Data Services",
            "type": "url",
            "url": "https://connect.plexus.com/sites/IT/Infrastructure/dataservices/_layouts/15/start.aspx#/"
         }, {
            "date_added": "13097100746769436",
            "id": "9",
            "meta_info": {
               "last_visited_desktop": "13139585977035410"
            },
            "name": "Cornerstone",
            "type": "url",
            "url": "https://plexus.csod.com/client/plexus/default.aspx?ReturnUrl=https%3a%2f%2fplexus.csod.com%2fLMS%2fcatalog%2fWelcome.aspx%3ftab_page_id%3d-67"
         }, {
            "date_added": "13123964577518097",
            "id": "56",
            "name": "Vi Cheat Sheet",
            "type": "url",
            "url": "http://www.lagmonster.org/docs/vi.html"
         }, {
            "date_added": "13097100746816236",
            "id": "11",
            "meta_info": {
               "last_visited_desktop": "13139932497232777"
            },
            "name": "GHQ Loc",
            "type": "url",
            "url": "http://ghqeus.plexus.com/"
         }, {
            "date_added": "13138196107346333",
            "id": "78",
            "meta_info": {
               "last_visited_desktop": "13138196107349059"
            },
            "name": "Pluralsight",
            "type": "url",
            "url": "https://app.pluralsight.com/id?redirectTo=/"
         }, {
            "date_added": "13139929998218424",
            "id": "81",
            "meta_info": {
               "last_visited_desktop": "13139929998219432"
            },
            "name": "kiteworks",
            "type": "url",
            "url": "https://www39.plexus.com/idp/module.php/accellion/loginuserpass.php?AuthState=_93685b14eb71be2de91354e74101a3c10ff28fafc6&RelayState=https%3A%2F%2Fwww39.plexus.com%2F#/login"
         } ],
         "date_added": "13103997734049233",
         "date_modified": "13139929998218424",
         "id": "1",
         "name": "Bookmarks bar",
         "type": "folder"
      },
      "other": {
         "children": [ {
            "date_added": "13097100747034636",
            "id": "17",
            "name": "SQL Server Updates",
            "type": "url",
            "url": "http://sqlserverupdates.com/"
         }, {
            "date_added": "13104013444626691",
            "id": "21",
            "name": "Script Generation",
            "type": "url",
            "url": "http://stackoverflow.com/questions/3488666/how-to-automate-script-generation-using-smo-in-sql-server"
         }, {
            "date_added": "13111889780195211",
            "id": "27",
            "name": "Speakeasy Speed Test",
            "type": "url",
            "url": "https://www.speakeasy.net/speedtest/"
         }, {
            "date_added": "13112798997304460",
            "id": "30",
            "name": "Phone Forward",
            "type": "url",
            "url": "https://neen-pbx-001:8443/ccmuser"
         }, {
            "date_added": "13113419910970515",
            "id": "33",
            "meta_info": {
               "last_visited_desktop": "13140284458303990"
            },
            "name": "VROPS - Prod",
            "type": "url",
            "url": "https://vrops.na.plexus.com/"
         }, {
            "date_added": "13113419934901996",
            "id": "34",
            "name": "VROPS - Dev",
            "type": "url",
            "url": "https://vrops-dev.na.plexus.com/"
         }, {
            "date_added": "13114617668877986",
            "id": "37",
            "name": "SQL Server on VMs",
            "type": "url",
            "url": "http://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/solutions/sql-server-on-vmware-best-practices-guide.pdf"
         }, {
            "date_added": "13114625847299297",
            "id": "38",
            "name": "Replication Stairway",
            "type": "url",
            "url": "http://www.sqlservercentral.com/stairway/72401/"
         }, {
            "date_added": "13115506048022773",
            "id": "41",
            "name": "Initialize a Transactional Subscription Without a Snapshot",
            "type": "url",
            "url": "https://msdn.microsoft.com/en-us/library/ms151705(v=sql.110).aspx"
         }, {
            "date_added": "13118963191117566",
            "id": "47",
            "meta_info": {
               "last_visited_desktop": "13139425199320932"
            },
            "name": "Powershell Default install",
            "type": "url",
            "url": "http://noc.plexus.com/doku.php/docs:application:powershell:00_start"
         }, {
            "date_added": "13119369326153926",
            "id": "50",
            "name": "On Call - Infrastructure",
            "type": "url",
            "url": "https://connect.plexus.com/sites/IT/Infrastructure/_layouts/15/start.aspx#/Lists/Infra%20OnCall%20Calendar"
         }, {
            "date_added": "13120842080681169",
            "id": "53",
            "name": "CommVault_Console",
            "type": "url",
            "url": "http://co-ap-305/console/"
         }, {
            "date_added": "13124216031268828",
            "id": "59",
            "meta_info": {
               "last_visited_desktop": "13139931215063546"
            },
            "name": "ComputerUser",
            "type": "url",
            "url": "http://sccmremote.plexus.com/reports/clientinfo.aspx"
         }, {
            "date_added": "13124924853108453",
            "id": "62",
            "name": "CommVault_Web",
            "type": "url",
            "url": "http://co-ap-305.na.plexus.com/webconsole/applications/"
         }, {
            "date_added": "13129741875813126",
            "id": "65",
            "name": "Color Picker",
            "type": "url",
            "url": "http://www.colorpicker.com/ff6969"
         }, {
            "date_added": "13133634166192825",
            "id": "68",
            "name": "Large Text Files",
            "type": "url",
            "url": "http://www.readfileonline.com/"
         }, {
            "date_added": "13100709219636191",
            "id": "19",
            "name": "vSphere - Dev (old)",
            "type": "url",
            "url": "https://vsphere-dev.na.plexus.com:9443/vsphere-client/#"
         }, {
            "date_added": "13136667447989800",
            "id": "75",
            "name": "ProGet Home",
            "type": "url",
            "url": "http://neen-ap-994:81/"
         }, {
            "date_added": "13134511834325374",
            "id": "72",
            "name": "PS Parallel",
            "type": "url",
            "url": "http://stackoverflow.com/questions/21418456/run-powershell-commands-in-parallel"
         }, {
            "date_added": "13097100746987836",
            "id": "16",
            "meta_info": {
               "last_visited_desktop": "13139491628829367"
            },
            "name": "SQL Server Install",
            "type": "url",
            "url": "http://noc/doku.php/docs:application:sql:install_sql_2008"
         } ],
         "date_added": "13103997734049240",
         "date_modified": "13136920416090309",
         "id": "2",
         "name": "Other bookmarks",
         "type": "folder"
      },
      "synced": {
         "children": [  ],
         "date_added": "13103997734049241",
         "date_modified": "0",
         "id": "3",
         "name": "Mobile bookmarks",
         "type": "folder"
      }
   },
   "version": 1
}
',
        
        -- other variables
        @name NVARCHAR(128),
        @url  NVARCHAR(2083),
        @position INT = 1;

DECLARE @tblBookmarks TABLE
(
    [Name] NVARCHAR(128),
    [Url]  NVARCHAR(2083)
);


WHILE 1 = 1
BEGIN
    SET @name = SUBSTRING
                (
                    @Bookmarks,
                    CHARINDEX(N'"name": "',@Bookmarks,@position) + 9,
                    CHARINDEX(N'"',@Bookmarks,CHARINDEX(N'"name": "',@Bookmarks,@position) + 9) - CHARINDEX(N'"name": "',@Bookmarks,@position) - 9
                );
    
    SET @position = CHARINDEX(N'"url": "',@Bookmarks,@position);

    IF @position = 0
        BREAK;

    SET @url  = SUBSTRING
                (
                    @Bookmarks,
                    CHARINDEX(N'"url": "',@Bookmarks,@position) + 8,
                    CHARINDEX(N'"',@Bookmarks,CHARINDEX(N'"url": "',@Bookmarks,@position) + 8) - CHARINDEX(N'"url": "',@Bookmarks,@position) - 8
                );

    IF ( (LOWER(@name) != N'Bookmarks bar') AND (LOWER(@name) != N'Other bookmarks') AND (LOWER(@name) != N'Mobile bookmarks') )
        INSERT INTO @tblBookmarks ([Name],[Url]) VALUES (@name,@url);

    SET @position = CHARINDEX(N'"name": "',@Bookmarks,@position) + 1;
END



SELECT * FROM @tblBookmarks;