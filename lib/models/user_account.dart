/// A locally stored account belonging to one app user.
class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.accountNumber,
  });

  final int id;
  final String name;
  final String email;
  final String accountNumber;

  factory UserAccount.fromMap(Map<String, Object?> map) => UserAccount(
    id: map['id'] as int,
    name: map['name'] as String,
    email: map['email'] as String,
    accountNumber: map['account_number'] as String,
  );
}
