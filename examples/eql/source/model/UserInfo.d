module model.UserInfo;

import hunt.entity;
import model.LoginInfo;


@Table("UserInfo")
class UInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    @Length(0,50)
    string nickName;
    
    @Max(150)
    int age;

}
