#include "engine.h"
#include "rendertarget.h"

static struct glaretexture : rendertarget
{
    bool dorender()
    {
        extern void drawglare();
        drawglare();
        return true;
    }
} glaretex;

void cleanupglare()
{
    glaretex.cleanup(true);
}

void viewglaretex()
{
    if(!GETIV(glare)) return;
    glaretex.debug();
}

bool glaring = false;

void drawglaretex()
{
    if(!GETIV(glare) || GETIV(renderpath)==R_FIXEDFUNCTION) return;

    glaretex.render(1<<GETIV(glaresize), 1<<GETIV(glaresize), GETIV(blurglare), GETIV(blurglaresigma)/100.0f);
}

void addglare()
{
    if(!GETIV(glare) || GETIV(renderpath)==R_FIXEDFUNCTION) return;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);

    SETSHADER(glare);

    glBindTexture(GL_TEXTURE_2D, glaretex.rendertex);

    setlocalparamf("glarescale", SHPARAM_PIXEL, 0, GETFV(glarescale), GETFV(glarescale), GETFV(glarescale));

    glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, 0);
    glTexCoord2f(1, 0); glVertex3f( 1, -1, 0);
    glTexCoord2f(0, 1); glVertex3f(-1,  1, 0);
    glTexCoord2f(1, 1); glVertex3f( 1,  1, 0);
    glEnd();

    glDisable(GL_BLEND);
}
     
