static const struct flaretype
{
    int type;             /* flaretex index, 0..5, -1 for 6+random shine */
    float loc;            /* postion on axis */
    float scale;          /* texture scaling */
    uchar alpha;          /* color alpha */
} flaretypes[] =
{
    {2,  1.30f, 0.04f, 153}, //flares
    {3,  1.00f, 0.10f, 102},
    {1,  0.50f, 0.20f, 77},
    {3,  0.20f, 0.05f, 77},
    {0,  0.00f, 0.04f, 77},
    {5, -0.25f, 0.07f, 127},
    {5, -0.40f, 0.02f, 153},
    {5, -0.60f, 0.04f, 102},
    {5, -1.00f, 0.03f, 51},
    {-1, 1.00f, 0.30f, 255}, //shine - red, green, blue
    {-2, 1.00f, 0.20f, 255},
    {-3, 1.00f, 0.25f, 255}
};

struct flare
{
    vec o, center;
    float size;
    vec color;
    bool sparkle;
};

VARP(flarecutoff, 0, 1000, 10000);
VARP(flaresize, 20, 100, 500);

struct flarerenderer : partrenderer
{
    int maxflares, numflares;
    unsigned int shinetime;
    flare *flares;

    flarerenderer(const char *texname, int maxflares, int flags = 0)
        : partrenderer(texname, 3, PT_FLARE|PT_SPECIAL|flags), maxflares(maxflares), shinetime(0)
    {
        flares = new flare[maxflares];
    }
    void reset()
    {
        numflares = 0;
    }

    void newflare(vec &o,  const vec &center, const vec &color, float mod, float size, bool sun, bool sparkle)
    {
        if(numflares >= maxflares) return;
        //occlusion check (neccessary as depth testing is turned off)
        vec dir = vec(camera1->o).sub(o);
        float dist = dir.magnitude();
        dir.mul(1/dist);
        if(raycube(o, dir, dist, RAY_CLIPMAT|RAY_POLY) < dist) return;
        flare &f = flares[numflares++];
        f.o = o;
        f.center = center;
        f.size = size;
        f.color = vec(color).mul(mod);
        f.sparkle = sparkle;
    }

    void addflare(vec &o, const vec &color, bool sun, bool sparkle)
    {
        //frustrum + fog check
        if(isvisiblesphere(0.0f, o) > (sun?VFC_FOGGED:VFC_FULL_VISIBLE)) return;
        //find closest point between camera line of sight and flare pos
        vec flaredir = vec(o).sub(camera1->o);
        vec center = vec(camdir).mul(flaredir.dot(camdir)).add(camera1->o);
        float mod, size;
        if(sun) //fixed size
        {
            mod = 1.0;
            size = flaredir.magnitude() * flaresize / 100.0f;
        }
        else
        {
            mod = (flarecutoff-vec(o).sub(center).squaredlen())/flarecutoff;
            if(mod < 0.0f) return;
            size = flaresize / 5.0f;
        }
        newflare(o, center, color, mod, size, sun, sparkle);
    }

    void update()
    {
        numflares = 0; //regenerate flarelist each frame
        shinetime = lastmillis/10;
    }

    int count()
    {
        return numflares;
    }

    bool haswork()
    {
        return (numflares != 0);
    }

    void render()
    {
        glDisable(GL_DEPTH_TEST);
        glBindTexture(GL_TEXTURE_2D, tex->id);
        gle::defattrib(gle::ATTRIB_VERTEX, 3, GL_FLOAT);
        gle::defattrib(gle::ATTRIB_TEXCOORD0, 2, GL_FLOAT);
        gle::defattrib(gle::ATTRIB_COLOR, 4, GL_FLOAT); 
        gle::begin(GL_QUADS);
        loopi(numflares)
        {
            const flare &f = flares[i];
            vec axis = vec(f.o).sub(f.center);
            float color[4] = {f.color[0], f.color[1], f.color[2], 1.0f};
            loopj(f.sparkle?12:9)
            {
                const flaretype &ft = flaretypes[j];
                vec o = vec(axis).mul(ft.loc).add(f.center);
                float sz = ft.scale * f.size;
                int tex = ft.type;
                if(ft.type < 0) //sparkles - always done last
                {
                    shinetime = (shinetime + 1) % 10;
                    tex = 6+shinetime;
                    color[0] = 0.0f;
                    color[1] = 0.0f;
                    color[2] = 0.0f;
                    color[-ft.type-1] = f.color[-ft.type-1]; //only want a single channel
                }
                color[3] = ft.alpha;
                const float tsz = 0.25; //flares are aranged in 4x4 grid
                float tx = tsz*(tex&0x03), ty = tsz*((tex>>2)&0x03);
                gle::attribf(o.x+(-camright.x+camup.x)*sz, o.y+(-camright.y+camup.y)*sz, o.z+(-camright.z+camup.z)*sz);
                    gle::attribf(tx,     ty+tsz);                                       
                    gle::attribv<4, float>(color);
                gle::attribf(o.x+( camright.x+camup.x)*sz, o.y+( camright.y+camup.y)*sz, o.z+( camright.z+camup.z)*sz);
                    gle::attribf(tx+tsz, ty+tsz);
                    gle::attribv<4, float>(color);
                gle::attribf(o.x+( camright.x-camup.x)*sz, o.y+( camright.y-camup.y)*sz, o.z+( camright.z-camup.z)*sz);
                    gle::attribf(tx+tsz, ty);
                    gle::attribv<4, float>(color);
                gle::attribf(o.x+(-camright.x-camup.x)*sz, o.y+(-camright.y-camup.y)*sz, o.z+(-camright.z-camup.z)*sz);
                    gle::attribf(tx,     ty);
                    gle::attribv<4, float>(color);
            }
        }
        gle::end();
        gle::disable();
        glEnable(GL_DEPTH_TEST);
    }

    //square per round hole - use addflare(..) instead
    particle *addpart(const vec &o, const vec &d, int fade, const vec &color, float size, int gravity = 0) { return NULL; }
};
static flarerenderer flares("<grey>media/particle/lensflares.png", 64);

