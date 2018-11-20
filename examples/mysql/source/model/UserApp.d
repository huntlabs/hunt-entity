module model.UserApp;

import hunt.entity;


@Table("UserApp")
class UserApp : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    int uid;
    int appid;

}
