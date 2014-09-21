// sound.cpp: basic positional sound using sdl_mixer

#include "engine.h"

#ifdef __APPLE__
  #include "SDL2_mixer/SDL_mixer.h"
#else
  #include "SDL_mixer.h"
#endif

#define MAXVOL MIX_MAX_VOLUME

bool nosound = true;

struct soundsample
{
    char *name;
    Mix_Chunk *chunk;

    soundsample() : name(NULL), chunk(NULL) {}
    ~soundsample() { DELETEA(name); }

    void cleanup() { if(chunk) { Mix_FreeChunk(chunk); chunk = NULL; } }
    bool load(const char *dir, bool msg = false);
};

struct soundchannel
{
    int id;
    bool inuse;
    vec loc;
    soundsample *sample;
    extentity *ent;
    int svolume, radius, volume, pan, flags;
    bool dirty;

    soundchannel(int id) : id(id) { reset(); }

    bool hasloc() const { return getloc().x >= -1e15f; }
    const vec &getloc() const { return ent ? ent->o : loc; }
    void clearloc() { loc = vec(-1e16f, -1e16f, -1e16f); }

    void reset()
    {
        inuse = false;
        clearloc();
        sample = NULL;
        ent = NULL;
        radius = 0;
        volume = svolume = -1;
        pan = -1;
        flags = 0;
        dirty = false;
    }
};
vector<soundchannel> channels;
int maxchannels = 0;

soundchannel &newchannel(int n, soundsample *sample, int volume, const vec *loc = NULL, extentity *ent = NULL, int flags = 0, int radius = 0)
{
    if(ent) ent->flags |= EF_SOUND;
    while(!channels.inrange(n)) channels.add(channels.length());
    soundchannel &chan = channels[n];
    chan.reset();
    chan.inuse = true;
    if(loc) chan.loc = *loc;
    chan.sample = sample;
    chan.ent = ent;
    chan.svolume = volume;
    chan.flags = 0;
    chan.radius = radius;
    return chan;
}

void freechannel(int n)
{
    if(!channels.inrange(n) || !channels[n].inuse) return;
    soundchannel &chan = channels[n];
    chan.inuse = false;
    if(chan.ent) chan.ent->flags &= ~EF_SOUND;
}

void syncchannel(soundchannel &chan)
{
    if(!chan.dirty) return;
    if(!Mix_FadingChannel(chan.id)) Mix_Volume(chan.id, chan.volume);
    Mix_SetPanning(chan.id, 255-chan.pan, chan.pan);
    chan.dirty = false;
}

void stopchannels()
{
    loopv(channels)
    {
        soundchannel &chan = channels[i];
        if(!chan.inuse) continue;
        Mix_HaltChannel(i);
        freechannel(i);
    }
}

void setmusicvol(int musicvol);
VARFP(soundvol, 0, 255, 255, if(!soundvol) { stopchannels(); setmusicvol(0); });
VARFP(musicvol, 0, 60, 255, setmusicvol(soundvol ? musicvol : 0));

char *musicfile = NULL, *musicdonecmd = NULL;

Mix_Music *music = NULL;
SDL_RWops *musicrw = NULL;
stream *musicstream = NULL;

void setmusicvol(int musicvol)
{
    if(nosound) return;
    if(music) Mix_VolumeMusic((musicvol*MAXVOL)/255);
}

void stopmusic()
{
    if(nosound) return;
    DELETEA(musicfile);
    DELETEA(musicdonecmd);
    if(music)
    {
        Mix_HaltMusic();
        Mix_FreeMusic(music);
        music = NULL;
    }
    if(musicrw) { SDL_FreeRW(musicrw); musicrw = NULL; }
    DELETEP(musicstream);
}

VARF(sound, 0, 1, 1, initwarning("sound configuration", INIT_RESET, CHANGE_SOUND));
VARF(soundchans, 1, 32, 128, initwarning("sound configuration", INIT_RESET, CHANGE_SOUND));
VARF(soundfreq, 0, 44100, 44100, initwarning("sound configuration", INIT_RESET, CHANGE_SOUND));
VARF(soundbufferlen, 128, 1024, 4096, initwarning("sound configuration", INIT_RESET, CHANGE_SOUND));

void initsound()
{
    if(!sound || Mix_OpenAudio(soundfreq, MIX_DEFAULT_FORMAT, 2, soundbufferlen)<0)
    {
        nosound = true;
        if(sound) conoutf(CON_ERROR, "sound init failed (SDL_mixer): %s", Mix_GetError());
        return;
    }
    Mix_AllocateChannels(soundchans);
    maxchannels = soundchans;
    nosound = false;
}

void musicdone()
{
    if(music) { Mix_HaltMusic(); Mix_FreeMusic(music); music = NULL; }
    if(musicrw) { SDL_FreeRW(musicrw); musicrw = NULL; }
    DELETEP(musicstream);
    DELETEA(musicfile);
    if(!musicdonecmd) return;
    char *cmd = musicdonecmd;
    musicdonecmd = NULL;
    execute(cmd);
    delete[] cmd;
}

Mix_Music *loadmusic(const char *name)
{
    if(!musicstream) musicstream = openzipfile(name, "rb");
    if(musicstream)
    {
        if(!musicrw) musicrw = musicstream->rwops();
        if(!musicrw) DELETEP(musicstream);
    }
    if(musicrw) music = Mix_LoadMUSType_RW(musicrw, MUS_NONE, 0);
    else music = Mix_LoadMUS(findfile(name, "rb"));
    if(!music)
    {
        if(musicrw) { SDL_FreeRW(musicrw); musicrw = NULL; }
        DELETEP(musicstream);
    }
    return music;
}

void startmusic(char *name, char *cmd)
{
    if(nosound) return;
    stopmusic();
    if(soundvol && musicvol && *name)
    {
        defformatstring(file, "media/%s", name);
        path(file);
        if(loadmusic(file))
        {
            DELETEA(musicfile);
            DELETEA(musicdonecmd);
            musicfile = newstring(file);
            if(cmd[0]) musicdonecmd = newstring(cmd);
            Mix_PlayMusic(music, cmd[0] ? 0 : -1);
            Mix_VolumeMusic((musicvol*MAXVOL)/255);
            intret(1);
        }
        else
        {
            conoutf(CON_ERROR, "could not play music: %s", file);
            intret(0);
        }
    }
}

COMMANDN(music, startmusic, "ss");

static Mix_Chunk *loadwav(const char *name)
{
    Mix_Chunk *c = NULL;
    stream *z = openzipfile(name, "rb");
    if(z)
    {
        SDL_RWops *rw = z->rwops();
        if(rw)
        {
            c = Mix_LoadWAV_RW(rw, 0);
            SDL_FreeRW(rw);
        }
        delete z;
    }
    if(!c) c = Mix_LoadWAV(findfile(name, "rb"));
    return c;
}

bool soundsample::load(const char *dir, bool msg)
{
    if(chunk) return true;
    if(!name[0]) return false;

    static const char * const exts[] = { "", ".wav", ".ogg" };
    string filename;
    loopi(sizeof(exts)/sizeof(exts[0]))
    {
        formatstring(filename, "media/sound/%s%s%s", dir, name, exts[i]);
        if(msg && !i) renderprogress(0, filename);
        path(filename);
        chunk = loadwav(filename);
        if(chunk) return true;
    }

    conoutf(CON_ERROR, "failed to load sample: media/sound/%s%s", dir, name);
    return false;
}

static struct soundtype
{
    hashnameset<soundsample> samples;
    const char *dir;
    int flags;

    soundtype(const char *dir, int flags) : dir(dir), flags(flags) {}

    soundsample *addsample(const char *name)
    {
        soundsample *s = samples.access(name);
        if(!s)
        {
            char *n = newstring(name);
            s = &samples[n];
            s->name = n;
            s->chunk = NULL;
        }
        return s;
    }

    void reset()
    {
        loopv(channels)
        {
            soundchannel &chan = channels[i];
            if(chan.inuse && flags == (chan.flags & SND_MAP))
            {
                Mix_HaltChannel(i);
                freechannel(i);
            }
        }
    }

    void cleanupsamples()
    {
        enumerate(samples, soundsample, s, s.cleanup());
    }

    void cleanup(bool full = true)
    {
        cleanupsamples();
        if(full) samples.clear();
    }

    bool preloadsound(const char *name)
    {
        if (nosound) return true;
        soundsample *s = addsample(name);
        return s->load(dir, true);
    }

    bool playing(const soundchannel &chan, const soundsample *sample, int volume) const
    {
        return chan.inuse && chan.sample == sample && chan.svolume == volume;
    }
} gamesounds("", 0), mapsounds("", SND_MAP);

void soundreset()
{
    gamesounds.reset();
}
COMMAND(soundreset, "");

void mapsoundreset()
{
    mapsounds.reset();
}
COMMAND(mapsoundreset, "");

void resetchannels()
{
    loopv(channels) if(channels[i].inuse) freechannel(i);
    channels.shrink(0);
}

void clear_sound()
{
    closemumble();
    if(nosound) return;
    stopmusic();

    gamesounds.cleanup();
    mapsounds.cleanup();
    Mix_CloseAudio();
    resetchannels();
}

void stopmapsounds()
{
    loopv(channels) if(channels[i].inuse && channels[i].ent)
    {
        Mix_HaltChannel(i);
        freechannel(i);
    }
}

void stopmapsound(extentity *e)
{
    loopv(channels)
    {
        soundchannel &chan = channels[i];
        if(chan.inuse && chan.ent == e)
        {
            Mix_HaltChannel(i);
            freechannel(i);
        }
    }
}

void checkmapsounds()
{
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        extentity &e = *ents[i];
        if(e.type!=ET_SOUND) continue;
        if(camera1->o.dist(e.o) < e.attr[0])
        {
            if(!(e.flags&EF_SOUND))
                lua::call_external("sound_play_map", "i", e.uid);
        }
        else if(e.flags&EF_SOUND) stopmapsound(&e);
    }
}

VAR(stereo, 0, 1, 1);

VARP(maxsoundradius, 0, 340, 10000);

bool updatechannel(soundchannel &chan)
{
    if(!chan.sample) return false;
    int vol = soundvol, pan = 255/2;
    if(chan.hasloc())
    {
        vec v;
        float dist = chan.getloc().dist(camera1->o, v);
        int rad = maxsoundradius;
        if(chan.ent)
        {
            rad = chan.ent->attr[0];
            if(chan.ent->attr[1])
            {
                rad -= chan.ent->attr[1];
                dist -= chan.ent->attr[1];
            }
        }
        else if(chan.radius > 0) rad = maxsoundradius ? min(maxsoundradius, chan.radius) : chan.radius;
        if(rad > 0) vol -= int(clamp(dist/rad, 0.0f, 1.0f)*soundvol); // simple mono distance attenuation
        if(stereo && (v.x != 0 || v.y != 0) && dist>0)
        {
            v.rotate_around_z(-camera1->yaw*RAD);
            pan = int(255.9f*(0.5f - 0.5f*v.x/v.magnitude2())); // range is from 0 (left) to 255 (right)
        }
    }
    vol = (vol*MAXVOL*chan.svolume)/255/255;
    vol = min(vol, MAXVOL);
    if(vol == chan.volume && pan == chan.pan) return false;
    chan.volume = vol;
    chan.pan = pan;
    chan.dirty = true;
    return true;
}

void reclaimchannels()
{
    loopv(channels)
    {
        soundchannel &chan = channels[i];
        if(chan.inuse && !Mix_Playing(i)) freechannel(i);
    }
}

void syncchannels()
{
    loopv(channels)
    {
        soundchannel &chan = channels[i];
        if(chan.inuse && chan.hasloc() && updatechannel(chan)) syncchannel(chan);
    }
}

void updatesounds()
{
    updatemumble();
    if(nosound) return;
    if(minimized) stopsounds();
    else
    {
        reclaimchannels();
        if(mainmenu) stopmapsounds();
        else checkmapsounds();
        syncchannels();
    }
    if(music)
    {
        if(!Mix_PlayingMusic()) musicdone();
        else if(Mix_PausedMusic()) Mix_ResumeMusic();
    }
}

VARP(maxsoundsatonce, 0, 7, 100);

VAR(dbgsound, 0, 0, 1);

int playsound(const char *s, const vec *loc, extentity *ent, int vol, int flags, int loops, int fade, int chanid, int radius, int expire)
{
    if(nosound || !soundvol || minimized) return -1;
    if(!vol) vol = 100;

    soundtype &sounds = ent || flags&SND_MAP ? mapsounds : gamesounds;

    soundsample *sample = sounds.addsample(s);

    if(loc && (maxsoundradius || radius > 0))
    {
        // cull sounds that are unlikely to be heard
        int rad = radius > 0 ? (maxsoundradius ? min(maxsoundradius, radius) : radius) : maxsoundradius;
        if(camera1->o.dist(*loc) > 1.5f*rad)
        {
            if(channels.inrange(chanid) && sounds.playing(channels[chanid], sample, vol))
            {
                Mix_HaltChannel(chanid);
                freechannel(chanid);
            }
            return -1;
        }
    }

    if(chanid < 0)
    {
        // avoid bursts of sounds with heavy packetloss and in sp
        static int soundsatonce = 0, lastsoundmillis = 0;
        if(totalmillis == lastsoundmillis) soundsatonce++; else soundsatonce = 1;
        lastsoundmillis = totalmillis;
        if(maxsoundsatonce && soundsatonce > maxsoundsatonce) return -1;
    }

    if(channels.inrange(chanid))
    {
        soundchannel &chan = channels[chanid];
        if(sounds.playing(chan, sample, vol))
        {
            if(loc) chan.loc = *loc;
            else if(chan.hasloc()) chan.clearloc();
            return chanid;
        }
    }
    if(fade < 0) return -1;

    if(!sample->chunk && !sample->load(sounds.dir)) return -1;

    if(dbgsound) conoutf("sound: %s%s", sounds.dir, sample->name);

    chanid = -1;
    loopv(channels) if(!channels[i].inuse) { chanid = i; break; }
    if(chanid < 0 && channels.length() < maxchannels) chanid = channels.length();
    if(chanid < 0) loopv(channels) if(!channels[i].volume) { Mix_HaltChannel(i); freechannel(i); chanid = i; break; }
    if(chanid < 0) return -1;

    soundchannel &chan = newchannel(chanid, sample, vol, loc, ent, flags, radius);
    updatechannel(chan);
    int playing = -1;
    if(fade)
    {
        Mix_Volume(chanid, chan.volume);
        playing = expire >= 0 ? Mix_FadeInChannelTimed(chanid, sample->chunk, loops, fade, expire) : Mix_FadeInChannel(chanid, sample->chunk, loops, fade);
    }
    else playing = expire >= 0 ? Mix_PlayChannelTimed(chanid, sample->chunk, loops, expire) : Mix_PlayChannel(chanid, sample->chunk, loops);
    if(playing >= 0) syncchannel(chan);
    else freechannel(chanid);
    return playing;
}

void stopsounds()
{
    loopv(channels) if(channels[i].inuse)
    {
        Mix_HaltChannel(i);
        freechannel(i);
    }
}

void resetsound()
{
    lua::call_external("changes_clear", "i", CHANGE_SOUND);
    if(!nosound)
    {
        gamesounds.cleanupsamples();
        mapsounds.cleanupsamples();
        if(music)
        {
            Mix_HaltMusic();
            Mix_FreeMusic(music);
        }
        if(musicstream) musicstream->seek(0, SEEK_SET);
        Mix_CloseAudio();
    }
    initsound();
    resetchannels();
    if(nosound)
    {
        DELETEA(musicfile);
        DELETEA(musicdonecmd);
        music = NULL;
        gamesounds.cleanup(false);
        mapsounds.cleanup(false);
        return;
    }
    if(music && loadmusic(musicfile))
    {
        Mix_PlayMusic(music, musicdonecmd ? 0 : -1);
        Mix_VolumeMusic((musicvol*MAXVOL)/255);
    }
    else
    {
        DELETEA(musicfile);
        DELETEA(musicdonecmd);
    }
}

COMMAND(resetsound, "");

#ifdef WIN32

#include <wchar.h>

#else

#include <unistd.h>

#ifdef _POSIX_SHARED_MEMORY_OBJECTS
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <wchar.h>
#endif

#endif

#if defined(WIN32) || defined(_POSIX_SHARED_MEMORY_OBJECTS)
struct MumbleInfo
{
    int version, timestamp;
    vec pos, front, top;
    wchar_t name[256];
};
#endif

#ifdef WIN32
static HANDLE mumblelink = NULL;
static MumbleInfo *mumbleinfo = NULL;
#define VALID_MUMBLELINK (mumblelink && mumbleinfo)
#elif defined(_POSIX_SHARED_MEMORY_OBJECTS)
static int mumblelink = -1;
static MumbleInfo *mumbleinfo = (MumbleInfo *)-1;
#define VALID_MUMBLELINK (mumblelink >= 0 && mumbleinfo != (MumbleInfo *)-1)
#endif

#ifdef VALID_MUMBLELINK
VARFP(mumble, 0, 1, 1, { if(mumble) initmumble(); else closemumble(); });
#else
VARFP(mumble, 0, 0, 1, { if(mumble) initmumble(); else closemumble(); });
#endif

void initmumble()
{
    if(!mumble) return;
#ifdef VALID_MUMBLELINK
    if(VALID_MUMBLELINK) return;

    #ifdef WIN32
        mumblelink = OpenFileMapping(FILE_MAP_ALL_ACCESS, FALSE, "MumbleLink");
        if(mumblelink)
        {
            mumbleinfo = (MumbleInfo *)MapViewOfFile(mumblelink, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(MumbleInfo));
            if(mumbleinfo) wcsncpy(mumbleinfo->name, L"Tesseract", 256);
        }
    #elif defined(_POSIX_SHARED_MEMORY_OBJECTS)
        defformatstring(shmname, "/MumbleLink.%d", getuid());
        mumblelink = shm_open(shmname, O_RDWR, 0);
        if(mumblelink >= 0)
        {
            mumbleinfo = (MumbleInfo *)mmap(NULL, sizeof(MumbleInfo), PROT_READ|PROT_WRITE, MAP_SHARED, mumblelink, 0);
            if(mumbleinfo != (MumbleInfo *)-1) wcsncpy(mumbleinfo->name, L"Tesseract", 256);
        }
    #endif
    if(!VALID_MUMBLELINK) closemumble();
#else
    conoutf(CON_ERROR, "Mumble positional audio is not available on this platform.");
#endif
}

void closemumble()
{
#ifdef WIN32
    if(mumbleinfo) { UnmapViewOfFile(mumbleinfo); mumbleinfo = NULL; }
    if(mumblelink) { CloseHandle(mumblelink); mumblelink = NULL; }
#elif defined(_POSIX_SHARED_MEMORY_OBJECTS)
    if(mumbleinfo != (MumbleInfo *)-1) { munmap(mumbleinfo, sizeof(MumbleInfo)); mumbleinfo = (MumbleInfo *)-1; }
    if(mumblelink >= 0) { close(mumblelink); mumblelink = -1; }
#endif
}

static inline vec mumblevec(const vec &v, bool pos = false)
{
    // change from X left, Z up, Y forward to X right, Y up, Z forward
    // 8 cube units = 1 meter
    vec m(-v.x, v.z, v.y);
    if(pos) m.div(8);
    return m;
}

void updatemumble()
{
#ifdef VALID_MUMBLELINK
    if(!VALID_MUMBLELINK) return;

    static int timestamp = 0;

    mumbleinfo->version = 1;
    mumbleinfo->timestamp = ++timestamp;

    mumbleinfo->pos = mumblevec(player->o, true);
    mumbleinfo->front = mumblevec(vec(player->yaw*RAD, player->pitch*RAD));
    mumbleinfo->top = mumblevec(vec(player->yaw*RAD, (player->pitch+90)*RAD));
#endif
}

/* OF */

CLUAICOMMAND(sound_play, void, (const char *name, float x, float y,
float z, int vol), {
    if (x || y || z) {
        vec loc(x, y, z);
        playsound(name, &loc, NULL, vol);
    } else {
        playsound(name, NULL, NULL, vol);
    }
});

CLUAICOMMAND(sound_play_map, bool, (int uid, const char *name, int vol,
int loops), {
    LUA_GET_ENT(entity, uid, "_C.sound_play_map", return false;);
    extentity *ent = entity->staticEntity;
    assert(ent);
    return playsound(name, NULL, ent, vol, SND_MAP, loops, 0, -1, 0, -1) >= 0;
})

CLUAICOMMAND(sound_stop, void, (const char *s, int vol), {
    loopv(channels) {
        soundchannel &chan = channels[i];
        if (chan.inuse && chan.svolume == vol && !strcmp(s, chan.sample->name)) {
            Mix_HaltChannel(i);
            freechannel(i);
        }
    }
});

CLUAICOMMAND(sound_stop_map, bool, (int uid), {
    LUA_GET_ENT(entity, uid, "_C.sound_stop_map", return false;);
    extentity *ent = entity->staticEntity;
    assert(ent);
    stopmapsound(ent);
    return true;
});

#define PRELOADFUN(type) \
    static bool preload##type##sound(const char *name) \
    { \
        if (!type##sounds.preloadsound(name)) { conoutf(CON_WARN, "cannot preload sound: %s", name); return false; } \
        return true; \
    }

PRELOADFUN(map)
PRELOADFUN(game)

CLUAICOMMAND(sound_preload_map, bool, (const char *name), {
    defformatstring(buf, "preloading sound '%s' ...", name);
    renderprogress(0, buf);
    return preloadmapsound(name);
});

ICOMMAND(preloadmapsound, "s", (char *name), {
    if (!name[0]) return;
    defformatstring(buf, "preloading sound '%s' ...", name);
    renderprogress(0, buf);
    intret(preloadmapsound(name));
});

CLUAICOMMAND(sound_preload_game, bool, (const char *name), {
    defformatstring(buf, "preloading sound '%s' ...", name);
    renderprogress(0, buf);
    return preloadgamesound(name);
});

ICOMMAND(preloadgamesound, "s", (char *name), {
    if (!name[0]) return;
    defformatstring(buf, "preloading sound '%s' ...", name);
    renderprogress(0, buf);
    intret(preloadgamesound(name));
});
