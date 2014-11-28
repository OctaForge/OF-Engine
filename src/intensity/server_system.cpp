/* teh ugly file of stubs */

#include "engine.h"

int thirdperson = 0;

void serverkeepalive()
{
    extern ENetHost *serverhost;
    if(serverhost)
        enet_host_service(serverhost, NULL, 0);
}

void renderprogress(float bar, const char *text)
{
    // Keep connection alive
    serverkeepalive();

    printf("|");
    for (int i = 0; i < 10; i++)
    {
        if (i < int(bar*10))
            printf("#");
        else
            printf("-");
    }
    printf("| %s\r", text);
    fflush(stdout);
}

void rotatebb(vec &center, vec &radius, int yaw, int pitch, int roll) {}

namespace game {
    bool allowedittoggle() { return false; }
    int parseplayer(const char *arg) { return -1; }
}

