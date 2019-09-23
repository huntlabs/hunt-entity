module model.IDCard;

import hunt.entity;
import model.UserInfo;

@Table("IDCard")
class IDCard : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string desc;

    @OneToOne()
    @JoinColumn("uid","id")
    UserInfo user;
}
