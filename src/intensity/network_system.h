#ifndef __NETWORK_SYSTEM_H__
#define __NETWORK_SYSTEM_H__

// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

//! We need a single 'dummy' client on the server, to which we relay position and message updates, as if it
//! were a real client.
#define DUMMY_SINGLETON_CLIENT_UNIQUE_ID -9000

namespace NetworkSystem
{
    namespace PositionUpdater
    {
        //! A non-optimized storage structure for a position update; in convenient
        //! form to read and write to in C++; the actual protocol message is different.
        //! This structure is used to gather all the info we are considering sending,
        //! all of that in quantized form. It does *not* contain further network message
        //! optimizations like bitfields, packing, unsent fields, etc.
        //! etc.
        //!
        //! For compression, we allow some of the fields here to not be present. Indicators
        //! for the fields are called has[X]; thus, hasPosition is true if this QuantizedInfo
        //! contains position info.
        struct QuantizedInfo
        {
        private:
            //! Internal utility, as this recurs a few times
            int getLifeSequence();

        public:
            int clientNumber;

            bool hasPosition; // Bit 1
            ivec position; // XXX: Currently we store these here as
                           // ints, but over the wire we send tham
                           // as unsigned. This is significantly
                           // better for bandwidth - 20%, even.
                           // This may be a problem if we let people
                           // move into positions with negative X,Y,Z

            bool hasYaw, hasPitch, hasRoll; // Bits 2-4
            unsigned char yaw, pitch, roll;

            bool hasVelocity; // Bit 5
            ivec velocity;

            bool hasFalling; // Bit 6
            ivec falling;

            bool hasMisc; // Bit 7 - represents physicsState (3 bits), lifeSequence (1 bit), move (2 bits), strafe (2 bits)
            unsigned char misc;

            bool crouching; // stuff this to indicator for now

            bool hasMapDefinedPositionData; // Bit 8 - see class fpsent
            unsigned int mapDefinedPositionData;

            QuantizedInfo() : hasPosition(true), hasYaw(true), hasPitch(true), hasRoll(true),
                              hasVelocity(true), hasFalling(true), hasMisc(true), crouching(true),
                              hasMapDefinedPositionData(true)
                { };

            //! Fills the fields with data from the given entity. Applies quantization
            //! as appropriate to each field, but nothing more.
            void generateFrom(fpsent *d);

            //! Fills the fields with data from the given buffer, whose source is the network.
            //! This is used both on the client and the server (the server just needs to
            //! read the appropriate number of bytes, and this is discarded).
            //! We receive quantized data, and leave it quantized here, but we do deal with
            //! compression like bitfields, packing, unsent fields, etc.
            void generateFrom(ucharbuf& p);

            //! Applies the fields to the appropriate entity (found using the clientNumber).
            //! This does the opposite of generateFrom(entity), i.e., it unquantizes the info.
            //! If the entity is not supplied, we look it up using its client number.
            void applyToEntity(fpsent *d = NULL);

            //! Applies the fields to a buffer, which can be send over the network. Leaves
            //! fields in quantized form. Applies compression of bitfields, packing, unsent
            //! fields, etc., i.e., the opposite of generateFrom(buffer).
            void applyToBuffer(ucharbuf& q);
        };
    }
}

#endif
