
libyojimbo_version = "0.2.0-preview3"

if os.is "windows" then
    sodium_debug = "sodium-debug"
    sodium_release = "sodium-release"
else
    sodium_debug = "sodium"
    sodium_release = "sodium"
end

solution "Yojimbo"
    platforms { "x64" }
    includedirs { "." }
    if not os.is "windows" then
        targetdir "bin/"  
    end
    configurations { "Debug", "Release" }
    flags { "ExtraWarnings", "FatalWarnings", "StaticRuntime", "FloatFast" }
    rtti "Off"
    configuration "Debug"
        flags { "Symbols" }
        defines { "DEBUG" }
    configuration "Release"
        optimize "Speed"
        defines { "NDEBUG" }

project "test"
    language "C++"
    kind "ConsoleApp"
    files { "test.cpp" }
    links { "yojimbo", "ucl" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

project "network_info"
    language "C++"
    kind "ConsoleApp"
    files { "network_info.cpp" }
    links { "yojimbo", "ucl" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

project "yojimbo"
    language "C++"
    kind "StaticLib"
    files { "yojimbo.h", "yojimbo.cpp", "yojimbo_*.h", "yojimbo_*.cpp" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

project "client"
    language "C++"
    kind "ConsoleApp"
    files { "client.cpp", "shared.h" }
    links { "yojimbo", "ucl" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

project "server"
    language "C++"
    kind "ConsoleApp"
    files { "server.cpp", "shared.h" }
    links { "yojimbo", "ucl" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

project "client_server"
    language "C++"
    kind "ConsoleApp"
    files { "client_server.cpp", "shared.h" }
    links { "yojimbo", "ucl" }
    configuration "Debug"
		links { sodium_debug }
	configuration "Release"
	    links { sodium_release }

if _ACTION == "clean" then
    os.rmdir "obj"
    os.rmdir "ipch"
	os.rmdir "bin"
	os.rmdir ".vs"
    os.rmdir "Debug"
    os.rmdir "Release"
    os.rmdir "docker/libyojimbo"
    if not os.is "windows" then
        os.execute "rm -f Makefile"
        os.execute "rm -f *.7z"
        os.execute "rm -f *.zip"
        os.execute "rm -f *.tar.gz"
        os.execute "rm -f *.zip"
        os.execute "rm -f *.make"
        os.execute "rm -f test"
        os.execute "rm -f network_info"
        os.execute "rm -f client"
        os.execute "rm -f server"
        os.execute "rm -f client_server"
        os.execute "rm -rf docker/libyojimbo"
        os.execute "find . -name .DS_Store -delete"
    else
        os.execute "del /F /Q Makefile"
        os.execute "del /F /Q *.make"
        os.execute "del /F /Q *.db"
        os.execute "del /F /Q *.opendb"
        os.execute "del /F /Q *.vcproj"
        os.execute "del /F /Q *.vcxproj"
        os.execute "del /F /Q *.vcxproj.user"
        os.execute "del /F /Q *.sln"
    end
end

if not os.is "windows" then

    newaction
    {
        trigger     = "release",
        description = "Create up a release of this project",
        execute = function ()
            _ACTION = "clean"
            premake.action.call( "clean" )
            files_to_zip = ".zip *.md *.cpp *.h premake5.lua sodium sodium-*.lib docker"
            os.execute( "rm -rf *.zip *.tar.gz *.7z" );
            os.execute( "rm -rf docker/libyojimbo" );
            os.execute( "zip -9r libyojimbo-" .. libyojimbo_version .. files_to_zip )
            os.execute( "7z a -mx=9 -p\"information wants to be free\" libyojimbo-" .. libyojimbo_version .. ".7z *.md *.cpp *.h premake5.lua sodium sodium-*.lib" )
            os.execute( "unzip libyojimbo-" .. libyojimbo_version .. ".zip -d libyojimbo-" .. libyojimbo_version );
            os.execute( "tar -zcvf libyojimbo-" .. libyojimbo_version .. ".tar.gz libyojimbo-" .. libyojimbo_version );
            os.execute( "rm -rf libyojimbo-" .. libyojimbo_version );
            os.execute( "echo" );
            os.execute( "echo \"*** SUCCESSFULLY CREATED RELEASE - libyojimbo-" .. libyojimbo_version .. " *** \"" );
            os.execute( "echo" );
        end
    }

    newaction
    {
        trigger     = "test",
        description = "Build and run all unit tests",
        execute = function ()
            if os.execute "make -j4 test" == 0 then
                os.execute "./bin/test"
            end
        end
    }

    newaction
    {
        trigger     = "info",
        description = "Build and run network info utility",
        execute = function ()
            if os.execute "make -j4 network_info" == 0 then
                os.execute "./bin/network_info"
            end
        end
    }

    newaction
    {
        trigger     = "yojimbo",
        description = "Build yojimbo client/server network protocol library",
        execute = function ()
            os.execute "make -j4 yojimbo"
        end
    }

    newaction
    {
        trigger     = "cs",
        description = "Build and run client/server testbed",     
        execute = function ()
            if os.execute "make -j4 client_server" == 0 then
                os.execute "./bin/client_server"
            end
        end
    }

    newoption 
    {
        trigger     = "serverAddress",
        value       = "IP[:port]",
        description = "Specify the server address that the client should connect to",
    }

    newaction
    {
        trigger     = "client",
        description = "Build and run client",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 client" == 0 then
                if _OPTIONS["serverAddress"] then
                    os.execute( "./bin/client " .. _OPTIONS["serverAddress"] )
                else
                    os.execute "./bin/client"
                end
            end
        end
    }

    newaction
    {
        trigger     = "server",
        description = "Build and run server",     
        execute = function ()
            if os.execute "make -j4 server" == 0 then
                os.execute "./bin/server"
            end
        end
    }

	newaction
	{
		trigger     = "docker",
		description = "Build and run a yojimbo server inside a docker container",
		execute = function ()
			os.execute "cd docker && ./copyFiles.sh && ./buildServer.sh && ./runServer.sh"
		end
	}

else

	newaction
	{
		trigger     = "docker",
		description = "Build and run a yojimbo server inside a docker container",
		execute = function ()
			os.execute "cd docker && copyFiles.bat && buildServer.bat && runServer.bat"
		end
	}

end