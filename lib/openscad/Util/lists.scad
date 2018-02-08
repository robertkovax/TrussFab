// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/List_Comprehensions
function concat_lists(L1, L2) = [for (i=[0:len(L1)+len(L2)-1])
                        i < len(L1)? L1[i] : L2[i-len(L1)]] ;
