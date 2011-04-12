
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"

#include "master.h"

namespace MasterServer
{

#ifdef CLIENT
//! Log in to the master server
void do_login(char *username, char *password)
{
    Logging::log(Logging::DEBUG, "Preparing to log in to master server with: %s / ----\r\n", username);

    std::string _username = username;
    std::string _password = password;

    if (_password == "--------") // If a password not entered, use the old (hashed) one
    {
        _password = GETSV(hashed_password);
    }

    REFLECT_PYTHON( login_to_master );

    boost::python::list ret = boost::python::list(login_to_master(_username, _password));
    bool success = boost::python::extract<bool>(ret[0]);
    if (success) {
        // Save password
        _password = boost::python::extract<std::string>(ret[1]);
        SETVF(hashed_password, _password.c_str());

        // Mark as logged in, and continue
        SETVF(logged_into_master, 1);
        lua::engine.exec("setup_main_menu()");
        conoutf("Logged in successfully");
    } else {
        SETVF(hashed_password, ""); // Remove the old saved password, for security
    }
}

void useLogin(std::string userId, std::string sessionId)
{
    REFLECT_PYTHON( use_master_login );
    use_master_login( userId, sessionId );

    SETVF(logged_into_master, 1);
    lua::engine.exec("setup_main_menu()");
}

void logout()
{
    SETV(logged_into_master, 0);
    lua::engine.exec("setup_main_menu()");
}

#endif

}

