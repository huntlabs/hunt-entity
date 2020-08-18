module model.AgentAsset;

import hunt.entity;


@Table("agent_asset")
class AgentAsset : Model {

    mixin MakeModel;

    @AutoIncrement
    @PrimaryKey
    ulong id;

    @Column("agent_id")
    ulong agentId;

    @Column("balance_amount")
    ulong balanceAmount;

    @Column("rebate_amount")
    ulong rebateAmount;

    @Column("credit_amount")
    ulong creditAmount;

    long created;

}
