import UserInfoAccount from 0x01;

transaction {

  prepare(admin: AuthAccount, user: AuthAccount) 
  {
    let adminRef = admin.borrow<&UserInfoAccount.Admin>(from: /storage/Admin)!;
    let newUserAcc <- adminRef.createNewUser();
    user.save<@UserInfoAccount.UserAsset>(<-newUserAcc, to: /storage/User);
    user.link<&UserInfoAccount.UserAsset>(/public/User, target: /storage/User);
  }
}
