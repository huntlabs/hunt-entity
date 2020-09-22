module model.UserApp;

import hunt.entity;


@Table("userapp")
class UserApp : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    int uid;
    int appid;

}
