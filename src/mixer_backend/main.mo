import Interface "icrc1_interface";
import Random "mo:base/Random";
import P "mo:base/Principal";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Result "mo:base/Result";
import List "mo:base/List";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat32 "mo:base/Nat32";
actor {
  //global icrc1 ledger
  let ICP = "ryjl3-tyaaa-aaaaa-aaaba-cai";
  let icp = actor (ICP) : Interface.Self;

  //persist random values across multiple computers
  let seed : Blob = "\14\C9\72\09\03\D4\D5\72\82\95\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3\6E\C7\B0\87\DC\76\08\69\14\CF";

  type MixedMemberData = {
    subAccount : Blob;
    mixer : Principal;
    amountHeld : Nat;
  };

  type MixedMember = TrieMap.TrieMap<Text, MixedMemberData>;

  stable var mixer_accounts : List.List<Principal> = List.nil<Principal>();
  stable var mixed_member_entries : [(Text, MixedMemberData)] = [];

  var mixed_members : MixedMember = TrieMap.fromEntries<Text, MixedMemberData>(mixed_member_entries.vals(), Text.equal, Text.hash);

  public shared (msg) func create_new_mixer() : async Result.Result<List.List<Principal>, Text> {
    if (P.isController(msg.caller)) {
      return #err "user not allowed to call this query";
    };

    let random_blob = await Random.blob();
    let principal_blob = Blob.fromArray(Iter.toArray(Array.slice<Nat8>((Blob.toArray(random_blob), 0, 29))));

    let principal = P.fromBlob(principal_blob);

    mixer_accounts := List.push<Principal>(principal, mixer_accounts);
    return #ok mixer_accounts;
  };

  // public

  public shared func regiser_mixer_member() : async Text {
    let random = Random.Finite(seed);
    let random_exp2 = Option.unwrap(random.range(32));
    let num_mixers = List.size<Principal>(mixer_accounts);
    let random_mixer = List.get<Principal>(mixer_accounts, random_exp2 % num_mixers);
    let random_blob = await Random.blob();
    let new_member : MixedMemberData = {
      amountHeld = 0;
      mixer = Option.unwrap(random_mixer);
      subAccount = random_blob;
    };

    let private_key = Nat32.toText(Blob.hash(await Random.blob()));
    mixed_members.put((private_key, new_member));

    return private_key;

  };

  public shared func transfer_from_mixer() : async () {

  };

  public query func get_all_mixers() : async List.List<Principal> {
    return mixer_accounts;
  };

  public shared func name() : async Text {
    await icp.icrc1_name();
  };

  public shared func metadata() : async [(Text, Interface.MetadataValue)] {
    await icp.icrc1_metadata();
  };

  public shared func minting_account() : async ?Interface.Account {
    await icp.icrc1_minting_account();
  };

  public shared func supported_standards() : async [Interface.StandardRecord] {
    await icp.icrc1_supported_standards();
  };

  public shared func total_supply() : async Nat {
    await icp.icrc1_total_supply();
  };

  public shared func balance(acc : Interface.Account) : async Nat {
    await icp.icrc1_balance_of(acc);
  };

  public shared func transfer(arg : Interface.TransferArg) : async Interface.Result {
    await icp.icrc1_transfer(arg);
  };

  //upgrade hooks
  system func preupgrade() {
    mixed_member_entries := Iter.toArray<(Text, MixedMemberData)>(mixed_members.entries());
  };

  system func postupgrade() {
    mixed_member_entries := [];
  };
};
