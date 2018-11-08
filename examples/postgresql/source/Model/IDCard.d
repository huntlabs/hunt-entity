module Model.IDCard;

import hunt.entity;
import Model.UserInfo;

@Table("idcard")
class IDCard  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    string desc;

    @OneToOne()
    @JoinColumn("uid","id")
    UserInfo user;
}
