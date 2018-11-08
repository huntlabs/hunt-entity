module Model.UserApp;

import hunt.entity;


@Table("userapp")
class UserApp  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    int uid;
    int appid;

}
