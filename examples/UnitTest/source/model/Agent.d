module model.Agent;

import hunt.entity;
import model.AgentAsset;


@Table("agent")
class Agent : Model {

    mixin MakeModel;

    @AutoIncrement
    @PrimaryKey
    ulong id;

    string username;

    string password;

    string salt;

    string name;

    // timestamp
    long created;

    // timestamp
    long updated;

    // 1: enabled, 0: disabled
    ushort status;

    string ip;

    @Column("admin_id")
    ulong adminId;

    @Column("code")
    string code;

    @OneToOne()
    @JoinColumn("id", "agent_id")
    AgentAsset asset;
}
