//! The main storage for LogicEntities and management of them. All entities appear in the central list
//! of logic entities here, as well as other scenario-wide data.

struct LogicSystem
{
    static bool initialized;

    //! Called before a map loads. Empties list of entities, and unloads the PC logic entity. Removes the lua engine
    static void clear(bool restart_lua = false);

    //! Calls clear(), and creates a new lua engine
    static void init();
};

