LuaQ     @scenemain.lua           5      A@  #@    A�  #@    A�  #@ @ �A E� #�     k   	@ �  k@  	@��  k�  	@ �  k�  	@��  k  	@ �  k@ 	@��  k� 	@ �  k� 	@��  k  	@ �+@ A� G@ A� G� A@ G  E  ��     I� �% �       require    strict 	   abplugin    button 
   SceneMain    Core    class    Sprite    init    onApplicationResume    onApplicationSuspend    onEnterBegin    onExitBegin    updateReward    checkAndShowDailyReward 
   saveState    onEnterFrame 	   MARGIN_X         	   MARGIN_Y    BUTTON_GAP       N@   initUI                +   � @ A  �@F�@ �  �@�� @ A  AFAA �  �@�� @ A  �AFAA �  �@�� @ A  �AFB �  �@�� @ A F�B �  �@�� @ � FC �  �@��@ �@  ƀ��C @  �@ � D �@ % �       addEventListener    Event    APPLICATION_RESUME    onApplicationResume    APPLICATION_SUSPEND    onApplicationSuspend    APPLICATION_EXIT    ENTER_FRAME    onEnterFrame    enterBegin    onEnterBegin 
   exitBegin    onExitBegin    abPluginRegisterCallback    AB_AD_REWARDED    updateReward    initUI     +                     	   	   	   	   	   	   
   
   
   
   
   
                                                                                    self     *   	   userData     *                      E   �@  c@ K�@ c@ % �       print    onApplicationResume    checkAndShowDailyReward                                self                           E   �@  c@ K�@ c@ % �       print    onApplicationSuspend 
   saveState                                self                           % �                     self                     &        K @ �@  ƀ��@ @  c@�K @ �@  � �AA @  c@�K @ �@  ƀ�AA @  c@�K @ �@  ���B @  c@�K @ �@  �@��B @  c@�% �       removeEventListener    Event    APPLICATION_RESUME    onApplicationResume    APPLICATION_SUSPEND    onApplicationSuspend    APPLICATION_EXIT    ENTER_FRAME    onEnterFrame    MY_AD_REWARDED    updateReward        !   !   !   !   !   !   "   "   "   "   "   "   #   #   #   #   #   #   $   $   $   $   $   $   %   %   %   %   %   %   &         self                (   ,        �   �@� �� ŀ    �@ % �       updateReward:     point    print        *   *   *   +   +   +   ,         self           event           text               /   0        % �            0         self                 2   3        % �            3         self                 5   7        �   �@@��� % �       os    timer        6   6   6   7         self           e           now               9   D        E   F@� �  �   c���   �@@� �   ���ˀ� A�  �@�ˀ@A�  �@�� � AA �@�� AA� �@��� �@� � @ 　�  % �    
   TextField    new 	   setScale       @   setTextColor              �oA   Button        :   :   :   :   :   ;   ;   ;   ;   ;   =   =   =   >   >   >   ?   ?   ?   @   @   @   B   B   B   B   B   C   D         text           text1          text2 
         button               J   j    R   E   F@� �  ��  c�����  �@��   �@ �� �   � �   A� #� K� �A � K�� c� BcA KB�A � K�Bc� O�BEB N�BcA K��A � K��c� O�BEB N��BcA KB�A � K�Bc� O�BEB N��BcA KD�A +  cA K��A +B  cA KD�A +�  cA K�D �� cA�K�D � cA�K�D ��cA�K�D � cA�% �    
   TextField    new    ABPluginExample 	   setScale       @   Show Offers    Show Video    Send Event    setPosition 	   MARGIN_X 	   MARGIN_Y 
   getHeight        @   BUTTON_GAP       @      @   addEventListener    click 	   addChild        W   Y            #@� % �       abPluginShowOffers        X   X   Y               Z   \            #@� % �       abPluginShowVideo        [   [   \               ]   c            @@ A�  ��  #��E   F@� �  �@ c���� �   � �� �     @� �@ �@ �     @� �@ % � 
      math    random       �?      $@              Y@   level_    print    level_complete    abPluginSendEvent        ^   ^   ^   ^   ^   _   _   _   _   _   `   `   `   a   a   a   a   a   b   b   b   b   b   c         level          score 
          R   K   K   K   K   K   L   L   L   M   M   M   N   N   N   O   O   O   Q   Q   Q   Q   Q   Q   Q   S   S   S   S   S   S   S   S   S   S   S   T   T   T   T   T   T   T   T   T   T   T   U   U   U   U   U   U   U   U   U   U   U   W   W   Y   W   Z   Z   \   Z   ]   ]   c   ]   f   f   f   g   g   g   h   h   h   i   i   i   j         self     Q      labelTitle    Q      buttonShowOffers    Q      buttonShowVideo    Q      buttonSendEvent    Q         createButton 5                                                                                     &       (   ,   (   /   0   /   2   3   2   5   7   5   D   F   F   G   G   H   H   J   j   j   J   j         createButton *   4       